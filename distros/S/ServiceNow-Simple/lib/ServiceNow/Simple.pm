package ServiceNow::Simple;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.10';

use Data::Dumper;
use FindBin;
use HTTP::Cookies;
use HTTP::Request::Common;
use LWP::UserAgent;
use SOAP::Lite;
use XML::Simple;
use Carp;
use File::Basename;
use MIME::Types;
use MIME::Base64 ();

$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;

our %config;
my $user;
my $pword;

BEGIN
{
    my $module = 'ServiceNow/Simple.pm';
    my $cfg = $INC{$module};
    unless ($cfg)
    {
        croak "Wrong case in use statement or $module module renamed. Perl is case sensitive!!!\n";
    }
    my $compiled = !(-e $cfg); # if the module was not read from disk => the script has been "compiled"
    $cfg =~ s/\.pm$/.cfg/;
    if ($compiled or -e $cfg)
    {
        # in a Perl2Exe or PerlApp created executable or PerlCtrl
        # generated COM object or the cfg is known to exist
        eval {require $cfg};
        if ($@ and $@ !~ /Can't locate /) #' <-- syntax higlighter
        {
            carp "Error in $cfg : $@\n";
        }
    }
}


sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};
    bless($self, $class);

    # Run initialisation code
    $self->_init(@_);

    return $self;
}


sub get
{
    my ($self, $args_h) = @_;

    my $method = $self->_get_method('get');
    my @params = $self->_load_args($args_h);
    my $result = $self->{soap}->call($method => @params);

    # Print faults to log file or stderr
    $self->_print_fault($result);

    if ($result && $result->body && $result->body->{'getResponse'})
    {
        return $result->body->{'getResponse'};
    }

    return;
}


sub get_keys
{
    my ($self, $args_h) = @_;

    my $method = $self->_get_method('getKeys');
    my @params = $self->_load_args($args_h);
    my $result = $self->{soap}->call($method => @params);

    # Print faults to log file or stderr
    $self->_print_fault($result);

    my $data_hr;
    if ($result && $result->body && $result->body->{'getKeysResponse'})
    {
        $data_hr = $result->body->{'getKeysResponse'};
    }

    if ($self->print_results())
    {
        print Data::Dumper->Dump([$data_hr], ['data_hr']) . "\n";
    }

    return $data_hr;
}


sub update
{
    # Note, one of the query_pairs must contain sys_id
    my ($self, $args_h) = @_;

    my $method = $self->_get_method('update');
    my @params = $self->_load_args($args_h);
    my $result = $self->{soap}->call($method => @params);

    # Print faults to log file or stderr
    $self->_print_fault($result);

    my $sys_id;
    if ($result && $result->body && $result->body->{updateResponse} && $result->body->{updateResponse}{sys_id})
    {
       $sys_id = $result->body->{updateResponse}{sys_id};
    }

    if ($self->print_results())
    {
        print Data::Dumper->Dump([$sys_id], ['sys_id']) . "\n";
    }

    return $sys_id;
}


sub get_records
{
    my ($self, $args_h) = @_;

    my $method = $self->_get_method('getRecords');

    # Check if we need to limit the columns returned.  Assume that IF there is a
    # __exclude_columns defined, it will over-ride this (and hence speed up the
    # process).  So __exclude_columns => undef is just a speed up, even though
    # there may be a LOT more data returned.
    my $the_columns;
    if ($args_h->{__columns} && ! exists($args_h->{__exclude_columns}))
    {
        $the_columns = $args_h->{__columns};
        delete $args_h->{__columns};

        if ($self->{instance_url} && $self->{__columns}{$self->{instance_url}}{$self->{table}}{$the_columns})
        {
            # We already have a list of fields to exclude for this form and __columns list
            $args_h->{__exclude_columns} = $self->{__columns}{$self->{instance_url}}{$self->{table}}{$the_columns};
        }
        elsif ($self->{instance} && $self->{__columns}{$self->{instance}}{$self->{table}}{$the_columns})
        {
            # We already have a list of fields to exclude for this form and __columns list
            $args_h->{__exclude_columns} = $self->{__columns}{$self->{instance}}{$self->{table}}{$the_columns};
        }
        else
        {
            # Do we have the list of fields for this form
            my @to_include = split /,/, $the_columns;
            my %all_fields;
            if ($self->{instance_url} && $self->{__columns}{__list}{$self->{instance_url}}{$self->{table}})
            {
                my $list = $self->{__columns}{__list}{$self->{instance_url}}{$self->{table}};
                %all_fields = map { $_ => 1 } split /,/, $list;
            }
            elsif ($self->{instance} && $self->{__columns}{__list}{$self->{instance}}{$self->{table}})
            {
                my $list = $self->{__columns}{__list}{$self->{instance}}{$self->{table}};
                %all_fields = map { $_ => 1 } split /,/, $list;
            }
            else
            {
                # Might as well query based on arguments passed, so remove what we don't want in query
                delete $args_h->{__exclude_columns};

                # Just get one record, to minimise data transfered
                my $original_limit = $args_h->{__limit};
                $args_h->{__limit} = 1;

                my @p = $self->_load_args($args_h);
                my $r = $self->{soap}->call($method => @p);

                # Add back in the limit if there was one, otherwise remove
                if ($original_limit)
                {
                    $args_h->{__limit} = $original_limit;
                }
                else
                {
                    delete $args_h->{__limit};
                }

                # GG handle no result!
                %all_fields = map { $_ => 1 } keys %{$r->body->{getRecordsResponse}{getRecordsResult}};

                # Store the full list in case we need it later
                if ($self->{instance_url})
                {
                    $self->{__columns}{__list}{$self->{instance_url}}{$self->{table}} = join(',', keys %all_fields);
                }
                else
                {
                    $self->{__columns}{__list}{$self->{instance}}{$self->{table}} = join(',', keys %all_fields);
                }
            }
            my @to_exclude;
            # Remove from the all fields hash those fields we want in the results
            # excluding the special meaning fields, those starting with '__'
            foreach my $ti (grep { $_ !~ /^__/} @to_include)
            {
                delete $all_fields{$ti};
            }

            # Add into the args we will pass
            $args_h->{__exclude_columns} = join(',', sort keys %all_fields);

            # Store for later use
            if ($self->{instance_url})
            {
                $self->{__columns}{$self->{instance_url}}{$self->{table}}{$the_columns} = $args_h->{__exclude_columns};
            }
            else
            {
                $self->{__columns}{$self->{instance}}{$self->{table}}{$the_columns} = $args_h->{__exclude_columns};
            }
        }
    }

    #__max_records   => 1000,
    #__chunks        => 200,
    #__callback      => 'write_csv',

    # If this is a __callback call we need to set __first_row, __last_row and iterate over the
    # possible result set.  Assume chunk size of 250 (default) unless __chunks is set.  Limit
    # the max number of records if __max_records is set.  Assume __first_row is 0 unless set.
    # Ignore __last_row and base on __chunks||250

    if ($args_h->{__callback})
    {
        # Store the callback function and remove it from the arguments hash
        my $callback = $args_h->{__callback};
        delete $args_h->{__callback};

        # Get the chunk size and clean up the arguments hash
        my $chunk_size = 250;
        if ($args_h->{__chunks})
        {
            $chunk_size = $args_h->{__chunks};
            delete $args_h->{__chunks};
        }

        my $max_records;
        if ($args_h->{__max_records})
        {
            $max_records = $args_h->{__max_records};
            delete $args_h->{__max_records};

            # max records takes precedence over chunk size
            if ($chunk_size > $max_records)
            {
                $chunk_size = $max_records;
            }
        }

        $args_h->{__first_row} = 0 unless $args_h->{__first_row};
        $args_h->{__last_row}  = $chunk_size;

        # Remove other things not relavent or useful :)
        delete $args_h->{__limits} if $args_h->{__limits};

        # If __columns, create an array of column names to pass
        my @columns;
        if ($the_columns)
        {
            @columns = split /,/, $the_columns;
        }

        # Make the first chunked call to ServiceNow
        my $total_records = 0;
        my @params = $self->_load_args($args_h);
        my $result = $self->{soap}->call($method => @params);

        # And now to the callback function
        my ($data_hr, $count) = $self->_getRecordsResponse($result);
        $total_records += $count;
        { $callback->($data_hr, 1, \@columns); }


        # Now chunk away...
        while ($count == $chunk_size && (!defined($max_records) || $total_records < $max_records))
        {
            # Sleep if we need to
            sleep($self->{__callback_sleep}) if $self->{__callback_sleep};

            # We need to get more
            $args_h->{__first_row} += $chunk_size;
            if (defined $max_records)
            {
                $args_h->{__last_row} = (($args_h->{__first_row} + $chunk_size) < $max_records) ? $args_h->{__first_row} + $chunk_size : $max_records;
            }
            else
            {
                $args_h->{__last_row} = $args_h->{__first_row} + $chunk_size;
            }

            @params = $self->_load_args($args_h);
            $result = $self->{soap}->call($method => @params);
            ($data_hr, $count) = $self->_getRecordsResponse($result);
            $total_records += $count;
            { $callback->($data_hr, 0, \@columns); }
        }
        return { count => $total_records, rows => undef };  # data handled by the callback function
    }
    else
    {
        my @params = $self->_load_args($args_h);
        my $result = $self->{soap}->call($method => @params);
        my ($data_hr, $count) = $self->_getRecordsResponse($result);

        return $data_hr;
    }
}


sub _getRecordsResponse
{
    my ($self, $result) = @_;

    my $count = 0;
    my $data_hr;
    if ($result && $result->body && $result->body->{getRecordsResponse} && $result->body->{getRecordsResponse}{getRecordsResult})
    {
        my $data = $result->body->{getRecordsResponse}{getRecordsResult};
        if (ref($data) eq 'HASH')
        {
            # There was only one record.  For consistant return, convert to array of hash
            $data_hr = { count => 1, rows => [ $data ] };
            $count = 1;
        }
        else
        {
            $count = scalar(@$data);
            $data_hr = { count => $count, rows => $data };
        }
    }

    # Print faults to log file or stderr
    $self->_print_fault($result);

    if ($self->print_results() && $data_hr)
    {
        print Data::Dumper->Dump([$data_hr], ['data_hr']) . "\n";
    }

    return ($data_hr, $count);
}


sub insert
{
    my ($self, $args_h) = @_;

    # Results:
    # --------
    # Regular tables:
    #   The sys_id field and the display value of the target table are returned.
    # Import set tables:
    #   The sys_id of the import set row, the name of the transformed target table (table),
    #   the display_name for the transformed target  table, the display_value of the
    #   transformed target row, and a status  field, which can contain inserted, updated,
    #   or error. There can be  an optional status_message field or an error_message field
    #   value when  status=error. When an insert did not cause a target row to be
    #   transformed, e.g. skipped because a key value is not specified, the sys_id field
    #   will contain the sys_id of the import set row rather than  the targeted transform table.
    # Import set tables with multiple transforms:
    #   The response from this type of insert will contain multiple sets of fields from the
    #   regular import set table insert wrapped in a multiInsertResponse parent element.
    #   Each set will contain a map field, showing which transform map created the response.

    my $method = $self->_get_method('insert');
    my @params = $self->_load_args($args_h);
    my $result = $self->{soap}->call($method => @params);

    # Print faults to log file or stderr
    $self->_print_fault($result);

    # insertResponse
    if ($result && $result->body && $result->body->{insertResponse})
    {
        return $result->body->{insertResponse};
    }

    return;
}


sub soap_debug
{
    SOAP::Lite->import(+trace => 'all');
}


sub print_results
{
    my ($self, $flag) = @_;

    if (defined $flag)
    {
        $self->{__print_results} = $flag;
    }
    return $self->{__print_results};
}


sub SOAP::Transport::HTTP::Client::get_basic_credentials
{
    return $user => $pword;
}


sub set_table
{
    my ($self, $table) = @_;

    $self->{table} = $table;
    $self->set_soap() if ($self->{instance} || $self->{instance_url});
    if(!$self->{wsdl} || ($self->{wsdl}{$self->{instance}} && !$self->{wsdl}{$self->{instance}}{$table}) || ($self->{wsdl}{$self->{instance_url}} && !$self->{wsdl}{$self->{instance_url}}{$table}))
    {
        $self->_load_wsdl($table);
    }
}

sub _get_table
{
    my $self = shift;

    return $self->{table};
}

sub set_instance
{
    my ($self, $instance) = @_;

    if ($self->{instance_url})
    {
        carp "instance_url is defined and will take precedence over a defined 'instance'\n";
    }

    $self->{instance} = $instance;
    $self->set_soap() if ($self->{table});
}


sub set_instance_url
{
    my ($self, $instance_url) = @_;

    if ($self->{instance})
    {
        carp "instance is defined, instance_url will take precedence over a defined 'instance'\n";
    }

    $self->{instance_url} = $instance_url;
    $self->set_soap() if ($self->{table});
}


sub set_soap
{
    my $self = shift;

    my $url;
    if ($self->{instance_url})
    {
        if ($self->{instance_url} !~ m{/$})
        {
            $self->{instance_url} .= '/';
        }
        $url = $self->{instance_url} . $self->{table} . '.do?SOAP';
    }
    else
    {
        $url = 'https://' . $self->{instance} . '.service-now.com/' . $self->{table} . '.do?SOAP';
    }

    # Do we need to show the display value for a reference field rather than the sys_id, or both
    if ($self->{__display_value} && !$self->{__plus_display_value})
    {
        $url .=  '&displayvalue=true';
    }
    elsif ($self->{__plus_display_value})
    {
        $url .=  '&displayvalue=all';
    }

    my %args = ( cookie_jar => HTTP::Cookies->new(ignore_discard => 1) ) ;
    if ($self->{proxy})
    {
        $args{proxy} = [ https => $self->{proxy}, http => $self->{proxy} ];
    }

    $self->{soap} = SOAP::Lite->proxy($url, %args);
}


sub _get_method
{
    my ($self, $method) = @_;

    $self->{method}  = $method;
    $self->{__fault} = undef;  # Clear any previous faults
    return SOAP::Data->name($method)->attr({xmlns => 'http://www.service-now.com/'});
}


sub _load_args
{
    my ($self, $args_h) = @_;
    my (@args, $k, $v);

    my $fld_details;
    if ($self->{instance_url})
    {
        $fld_details = $self->{wsdl}{$self->{instance_url}}{$self->{table}}{$self->{method}};
    }
    else
    {
        $fld_details = $self->{wsdl}{$self->{instance}}{$self->{table}}{$self->{method}};
    }

    while (($k, $v) = each %$args_h)
    {
        if ($fld_details->{$k})
        {
            (my $type = $fld_details->{$k}{type}) =~ s/xsd://gms;
            push @args, SOAP::Data->name( $k => $v )->type($type);
        }
        else
        {
            push @args, SOAP::Data->name( $k => $v );
        }
    }

    # Add in the limits if not in the arguments and defined in object
    if (! $args_h->{__limit} && $self->{__limit})
    {
        push @args, SOAP::Data->name( __limit => $self->{__limit} );
    }

    return @args;
}


sub _print_fault
{
    my ($self, $result) = @_;

    if ($result->fault)
    {
        no warnings qw(uninitialized);
        if ($self->{__log})
        {
            $self->{__log}->exp('E930 - faultcode   =' . $result->fault->{faultcode}   . "\n",
                                       'faultstring =' . $result->fault->{faultstring} . "\n",
                                       'detail      =' . $result->fault->{detail}      . "\n");
        }
        else
        {
            carp 'faultcode   =' . $result->fault->{faultcode}   . "\n" .
                 'faultstring =' . $result->fault->{faultstring} . "\n" .
                 'detail      =' . $result->fault->{detail}      . "\n";
        }

        # Store the fault so it can be queried before the next ws call
        # Cleared in _get_method()
        $self->{__fault}{faultcode}   = $result->fault->{faultcode};
        $self->{__fault}{faultstring} = $result->fault->{faultstring};
        $self->{__fault}{detail}      = $result->fault->{detail};
    }
}


sub _load_wsdl
{
    my ($self, $table) = @_;

    my $ua = LWP::UserAgent->new();

    if ($self->{instance_url})
    {
        # Not sure if this is correct for instance_url case, since I have not been able to test it?
        # expect instance_url format to be https://instance_url/
        if ($self->{instance_url} =~ m{https?://([^/]+)/?$})
        {
            $ua->credentials($1 . ':443', 'Service-now', $user, $pword);
        }
        else
        {
            # Not in the format we expected...
            carp '_load_wsdl instance_url format expected as https://instance_url/ but was ' . $self->{instance_url} . ", skipping WDSL load.\n";
            return;
        }
    }
    else
    {
        $ua->credentials($self->{instance} . '.service-now.com:443', 'Service-now', $user, $pword);
    }

    # Note:  There is no advantage in including the displayvalue=1 or displayvalue=all in the WSDL request
    #        in the case of displayvalue=all, the dv_ fields can not be excluded for fields you do request
    #        (or more accurately, fields you don't exclude)
    my $response;
    if ($self->{instance_url})
    {
        $response = $ua->get($self->{instance_url} . $table . '.do?WSDL');
    }
    else
    {
        $response = $ua->get('https://' . $self->{instance} . '.service-now.com/' . $table . '.do?WSDL');
    }
    if ($response->is_success())
    {
        #my $wsdl = XMLin($response->content, ForceArray => 1);
        #$XML::Simple::PREFERRED_PARSER = '';
        my $wsdl = XMLin($response->content);

        foreach my $method (grep { $_ !~ /Response$/ } keys %{ $wsdl->{'wsdl:types'}{'xsd:schema'}{'xsd:element'} })
        {
            #print "Method=$method\n";
            my $e = $wsdl->{'wsdl:types'}{'xsd:schema'}{'xsd:element'}{$method}{'xsd:complexType'}{'xsd:sequence'}{'xsd:element'};
            foreach my $fld (keys %{ $e })
            {
                #print "\n\n", join("\n", keys %{ $wsdl->{'wsdl:types'}{'xsd:schema'}{'xsd:element'}{deleteMultiple}{'xsd:complexType'}{'xsd:sequence'}{'xsd:element'} }), "\n";
                #print "  $fld => $e->{$fld}{type}\n";
                if ($self->{instance_url})
                {
                    $self->{wsdl}{$self->{instance_url}}{$table}{$method}{$fld} = $e->{$fld};
                }
                else
                {
                    $self->{wsdl}{$self->{instance}}{$table}{$method}{$fld} = $e->{$fld};
                }
            }
        }
    }
}


sub set_display_value
{
    my ($self, $flag) = @_;

    $self->{__display_value} = $flag;
    $self->set_soap();
}


sub set_plus_display_value
{
    my ($self, $flag) = @_;

    $self->{__plus_display_value} = $flag;
    $self->set_soap();
    $self->_load_wsdl($self->{table});
}


sub _get_file_base64
{
    my ($self, $filename) = @_;
    my $fh;
    unless (open($fh, '<', $filename))
    {
        carp("Failed to open file $filename for reading $!\n");
        return;
    }

    # If you want to encode a large file, you should encode it in chunks that are a multiple of 57 bytes.
    # This ensures that the base64 lines line up and that you do not end up with padding in the middle.
    # 57 bytes of data fills one complete base64 line (76 == 57*4/3):
    my $base64;
    my $bytes;
    while (read($fh, $bytes, 60*57))
    {
        $base64 .= MIME::Base64::encode($bytes);
    }
    close $fh;

    return $base64;
}


sub add_attachment
{
    my ($self, $args_h) = @_;

    my $method = $self->_get_method('insert');

    # The required arguments
    my $file_name = $args_h->{file_name};
    my $table     = $args_h->{table};
    my $sys_id    = $args_h->{sys_id};

    carp("Required parameters are file_name, table and sys_id\n") unless ($file_name && $table && $sys_id);

    my ($name, $path, $suffix) = fileparse($file_name, '\.[^.]+$');

    my $mt   = MIME::Types->new;
    my $type = $mt->mimeTypeOf($suffix);

    # Make sure we have a type
    $type = 'application/octet-stream' unless $type;

    my $base64 = $self->_get_file_base64($file_name);

    # Change to the correct table, storing the previous so we can reinstate it
    my $prev_table = $self->_get_table();
    $self->set_table('ecc_queue');

    my %params = (
        agent   => 'ServiceNow::Simple',
        topic   => 'AttachmentCreator',                   # Required
        name    => join(':', $name . $suffix, $type),   # File name and required MIME type
        source  => join(':', $table, $sys_id),            # The table and sys_id of the record the attachment relates to
        payload => $base64,                               # The base64 encoded file
        );
    #print STDERR Dumper(\%params), "\n";
    my @params = $self->_load_args(\%params);
    my $result = $self->{soap}->call($method => @params);

    # Print faults to log file or stderr
    $self->_print_fault($result);

    # insertResponse
    if ($result && $result->body && $result->body->{insertResponse})
    {
        return $result->body->{insertResponse};
    }

    # Restore to the previous table, so no one knows we were here :)
    $self->set_table($prev_table);

    return;
}


sub _init
{
    my ($self, $args) = @_;

    # Did we have any of the persistant variables passed
    my $k = '5Jv@sI9^bl@D*j5H3@:7g4H[2]d%Ks314aNuGeX;';
    if ($args->{user})
    {
        $self->{persistant}{user} = $args->{user};
    }
    else
    {
        if (defined $config{user})
        {
            my $s = pack('H*', $config{user});
            my $x = substr($k, 0, length($s));
            my $u = $s ^ $x;
            $self->{persistant}{user} = $u;
        }
        else
        {
            carp "No user defined, quitting\n";
            exit(1);
        }
    }

    if ($args->{password})
    {
        $self->{persistant}{password} = $args->{password};
    }
    else
    {
        if (defined $config{password})
        {
            my $s = pack('H*', $config{password});
            my $x = substr($k, 0, length($s));
            my $u = $s ^ $x;
            $self->{persistant}{password} = $u;
        }
        else
        {
            carp "No password defined, quitting\n";
            exit(2);
        }
    }
    if ($args->{proxy})
    {
        $self->{persistant}{proxy} = $args->{proxy};
    }
    elsif (defined $config{proxy})
    {
        $self->{persistant}{proxy} = $config{proxy};
    }
    $user  = $self->{persistant}{user};
    $pword = $self->{persistant}{password};

    # Stop environment variable from playing around with SOAP::Lite
    if ($args->{__remove_env_proxy})
    {
        delete $ENV{HTTP_proxy}  if $ENV{HTTP_proxy};
        delete $ENV{HTTPS_proxy} if $ENV{HTTPS_proxy};
    }
    elsif ($self->{persistant}{proxy} && !$ENV{HTTPS_proxy})
    {
        $ENV{HTTPS_proxy} = $self->{persistant}{proxy};
    }


    # Handle the other passed arguments
    $self->{__display_value} = $args->{__display_value} ? 1 : 0;
    $self->{__plus_display_value} = $args->{__plus_display_value} ? 1 : 0;
    $self->set_instance($args->{instance})              if $args->{instance};
    $self->set_instance_url($args->{instance_url})      if $args->{instance_url};
    $self->set_table($args->{table})                    if $args->{table};     # Important this is after instance
    $self->{__limit}         = $args->{__limit}         if $args->{__limit};
    $self->{__log}           = $args->{__log}           if $args->{__log};
    $self->{__print_results} = $args->{__print_results} if $args->{__print_results};   # Print results to stdout
    $self->soap_debug()                                 if $args->{__soap_debug};
    if ($args->{table} && ($args->{instance} || $args->{instance_url}))
    {
        $self->set_soap();
    }
}

#####################################################################
# DO NOT REMOVE THE FOLLOWING LINE, IT IS NEEDED TO LOAD THIS LIBRARY
1;


__END__

=head1 NAME

ServiceNow::Simple - Simple yet powerful ServiceNow API interface

=head1 SYNOPSIS

B<Note:> To use the SOAP web services API the user you use must have
the appropriate 'soap' role(s) (there are a few) and the table/fields
must have access for the appropriate 'soap' role(s) if they are not open.
This is true, whether you use this module or other web services to interact
with ServiceNow.

There is a ServiceNow demonstration instance you can play with if you are unsure.
Try C<https://demo019.service-now.com/navpage.do> using user 'admin' with password
'admin'.  You will need to give the 'admin' user the 'soap' role and change the ACL
for sys_user_group to allow read and write for the 'soap' role (see the Wiki
C<http://wiki.servicenow.com/index.php?title=Main_Page> on how).  Tables that are open
do not need the ACL changes to allow access via these API's.

  use ServiceNow::Simple;

  ## Normal (minimal) use
  #######################
  my $sn = ServiceNow::Simple->new({ instance => 'some_name', table => 'sys_user' });
  # where your instance is https://some_name.service-now.com


  ## All options to new
  #####################
  my $sn = ServiceNow::Simple->new({
      instance             => 'some_name',
      instance_url         => 'http://some_name.something/',   # Not instance_url takes precedence over 'instance'
      table                => 'sys_user',
      __display_value      => 1,            # Return the display value for a reference field
      __plus_display_value => 1,            # Return the display value for a reference field AND the sys_id
      __limit              => 23,           # Maximum records to return
      __log                => $log,         # Log to a File::Log object
      __print_results      => 1,            # Print
      __soap_debug         => 1,            # Print SOAP::Lite debug details
      __remove_env_proxy   => 1,            # Delete any http proxy settings from environment
      });


  ## Get Keys
  ###########
  my $sn = ServiceNow::Simple->new({
      instance        => 'instance',
      table           => 'sys_user_group',
      user            => 'itil',
      password        => 'itil',
      });

  my $results = $sn->get_keys({ name => 'Administration' });
  # Single match:
  # $results = {
  #   'count' => '1',
  #   'sys_id' => '23105e1f1903ac00fb54sdb1ad54dc1a'
  # };

  $results = $sn->get_keys({ __encoded_query => 'GOTOnameSTARTSWITHa' });
  # Multi record match:
  # $results = {
  #   'count' => '6',
  #   'sys_id' => '23105e1f1903ac00fb54sdb1ad54dc1a,2310421b1cae0100e6ss837b1e7aa7d0,23100ed71cae0100e6ss837b1e7aa797,23100ed71cae0100e6ss837b1e7aa79d,2310421b1cae0100e6ss837b1e7aa7d4,231079c1b84ac5009c86fe3becceed2b'
  # };

  ## Insert a record
  ##################
  # Change table before insert
  $sn->set_table('sys_user');
  # Do the insert
  my $result = $sn->insert({
      user_name => 'GNG',
      name => 'GNG Test Record',
      active => 'true',
  });
  # Check the results, if there is an error $result will be undef
  if ($result)
  {
      print Dumper($result), "\n";
      # Sample success result:
      # $VAR1 = {
      #   'name' => 'GNG Test Record',
      #   'sys_id' => '2310f10bb8d4197740ff0d351492f271'
      # };
  }
  else
  {
      print Dumper($sn->{__fault}), "\n";
      # Sample failure result:
      # $VAR1 = {
      #   'detail' => 'com.glide.processors.soap.SOAPProcessingException: Insert Aborted : Error during insert of sys_user (GNG Test Record)',
      #   'faultcode' => 'SOAP-ENV:Server',
      #   'faultstring' => 'com.glide.processors.soap.SOAPProcessingException: Insert Aborted : Error during insert of sys_user (GNG Test Record)'
      # };
  }


  ## Get Records
  ##############
  my $sn = ServiceNow::Simple->new({
      instance        => 'some_name',
      table           => 'sys_user_group',
      __print_results => 1,
      });
  my $results = $sn->get_records({ name => 'Administration', __columns => 'name,description' });
  # Sample as printed to stdout, __print_results (same as $results):
  # $data_hr = {
  #   'count' => 1,
  #   'rows' => [
  #     {
  #       'description' => 'Administrator group.',
  #       'name' => 'Administration'
  #     }
  #   ]
  # };

  # Encoded query with minimal returned fields
  $results = $sn->get_records({ __encoded_query => 'GOTOnameSTARTSWITHa', __columns => 'name,email' });
  # $results = {
  #   'count' => 2,
  #   'rows' => [
  #     {
  #       'email' => '',
  #       'name' => 'Administration'
  #     },
  #     {
  #       'email' => 'android_dev@my_org.com',
  #       'name' => 'Android'
  #     },
  #   ]
  # };


  ## Update
  #########
  my $r = $sn->update({
      sys_id => '97415d1f1903ac00fb54adb1ad54dc1a',    ## REQUIRED, sys_id must be provided
      active => 'true',                                #  Other field(s)
      });  # Administration group, which should always be defined, set 'Active' to true
  # $r eq '97415d1f1903ac00fb54adb1ad54dc1a'

  ## Change to another table
  ##########################
  $sn->set_table('sys_user');

  ## Change to another instance
  #############################
  $sn->set_instance('my_dev_instance');

  ## SOAP debug messages
  ##########################
  $sn->soap_debug(1);  # Turn on
  ... do something
  $sn->soap_debug(0);  # Turn off

=head1 KEY FEATURES

=over 4

=item *

Caching of user, password and proxy - one place to change and user and password
is not scattered through many scripts

=item *

Results in simple I<perlish> style.  Ensures consistancy of returned types, AVOIDS
an array of hashes for many items and a hash for one item, thereby keeping your
code simpler

=item *

Arguments are I<'typed'> as per the WSDL.  This avoids UTF-8/16 data being encoded
as base64 when it should be a string.

=item *

Allows returning of only those fields you require by defining them, rather than
defining all the fields you don't want!  See __columns below.  This can save a
lot of bandwidth when getting records.

=item *

Persistant HTTP session across all SOAP calls

=back

=head1 MAIN METHODS

The set of methods that do things on ServiceNow and return useful information

=head2 new

new creates a new 'ServiceNow::Simple' object.  Parameters are passed in a hash reference.
It requires that the B<instance> of ServiceNow and the initial B<table> be defined.
The B<instance> is the I<some_name> in https://some_name.service-now.com.  The B<table> is
the database name on the table to be operated on, for example the 'User' table is I<sys_user>.

The parameters that can be passed are:

=over 4

=item instance

REQUIRED unless instance_url is defined. The ServiceNow instance that ServiceNow::Simple should connect to.
This is the normal approach and I<instance_url> is only provided for special cases where the normal URL
is not:

 instance.service-now.com

=item instance_url

Alternative to defining I<instance>.  B<Note:> it is intended that this only be used where I<instance> can
not be used.  This was added in version 0.08 after a suggestion from John Andersen.

=item table

REQUIRED. The table that ServiceNow::Simple will operate on unless changed with I<table()> method

=item user

The I<user> that ServiceNow::Simple will connect to the instance as.  Note that this user
will need to have one or more of the 'soap' roles.  B<Note:> if the configuration has been
run and the user and password defined, this argument is not required.  It can be used to over-ride
the configuration value.  See the 'simple.cfg' file located in the same location as the Simple.pm
file.  Note that the data in Simple.cfg is obfuscated (at least for user and password)

=item password

The password for the I<user>, see user above.

=item __limit

Set the limit on the number of records that will be returned.  By default this is 250 records.
Settting this in the I<new> method will apply this limit to all further calls unless that call
defines it's own __limit.

= item __display_value

If set to true is will alter the way reference field information is returned.  By default or if
false a reference field will return the sys_id of the record.  If set to true, the value returned
is the display value (what you would see if looking at the form).  This can also be set using the
I<set_display_value()> method.

= item __plus_display_value

Similar to __display_value above but the display value and the sys_id are given.  The display value
field is prefixed by B<dv_>, so for example the department field on the User table [sys_user]
would appear twice, once as I<dv_department> giving the name and once as I<department> giving the sys_id.
This can also be set using the I<set_plus_display_value()> method.

B<Note:> Using __plus_display_value results in additional data being returned from the server, the dv_
record is always returned for fields not excluded and they themselfs can not be excluded (for a field
you do want).  If you have excluded (or not asked for with __columns) then the field and dv_field are
excluded.

=item __print_results

If true, results return will also be printed to STDOUT using Date::Dumper's Dump method.
See the I<print_results()> method.

=item __log

Used to define the log object.  This can be a File::Log object or another log object that implements
the I<msg(level, message)> and I<exp(message)> methods.

=item __soap_debug

If true, with activate soap debug messages.  See also the I<soap_debug()> method.

=item __remove_env_proxy

If true, remove any HTTPS_proxy or HTTP_proxy environment variables (generally you should not need this)

=back

=head2 get

Query a single record from the targeted table by sys_id and return the record and its fields.
So the expected argument (hash reference) would be { sys_id => <the_sys_id> } and could also
include:

=over 4

=item __exclude_columns

Specify a list of comma delimited field names to exclude from the result set

=item __columns

The opposite (and more useful IMHO) of __exclude_columns, define that field name you want returned.
Often this is a much smaller list.

=item __use_view

Specify a Form view by name, to be used for limiting and expanding the results returned.
When the form view contains deep referenced fields eg. caller_id.email, this field will be returned in the result as well

=back

The get() returns a hash reference where the keys are the field names.

Example (that should run against the ServiceNow demo instance):

 use ServiceNow::Simple;
 use Data::Dumper;

 my $sn = ServiceNow::Simple->new({
     instance => 'demo019',
     user     => 'admin',
     password => 'admin',
     table    => 'sys_user_group',
     });

 # THIS IS ONLY CALLED TO GET THE SYS_ID FOR THE GET CALL
 my $results = $sn->get_keys({ name => 'CAB Approval' });

 my $r = $sn->get({ sys_id => $results->{sys_id} });
 print Dumper($r), "\n";

 # Output from Dumper
 $VAR1 = {
   'active' => '1',
   'cost_center' => '',
   'default_assignee' => '',
   'description' => 'CAB approvers',
   'email' => '',
   'exclude_manager' => '0',
   'include_members' => '0',
   'manager' => '',
   'name' => 'CAB Approval',
   'parent' => '',
   'roles' => '',
   'source' => '',
   'sys_created_by' => 'admin',
   'sys_created_on' => '2011-09-30 16:30:34',
   'sys_id' => 'b85d44954a3623120004689b2d5dd60a',
   'sys_mod_count' => '0',
   'sys_updated_by' => 'admin',
   'sys_updated_on' => '2011-09-30 16:30:34',
   'type' => ''
 };

=head2 get_keys

Query the targeted table by example values and return a comma delimited list of sys_id.
Example values are key/value pairs where the key is the field name and the value is the
value you want to match.  You can also use an __encoded_query.  See OTHER FIELD ARGUMENTS
below.

  $results = $sn->get_keys({ active => true, site_name => 'knoxfield', __limit => 6, });
  # Multi record match:
  # $results = {
  #   'count' => '6',
  #   'sys_id' => '23105e1f1903ac00fb54sdb1ad54dc1a,2310421b1cae0100e6ss837b1e7aa7d0,23100ed71cae0100e6ss837b1e7aa797,23100ed71cae0100e6ss837b1e7aa79d,2310421b1cae0100e6ss837b1e7aa7d4,231079c1b84ac5009c86fe3becceed2b'
  # };


=head2 get_records

Query the targeted table by example values and return all matching records and their fields.
See OTHER FIELD ARGUMENTS.

   my $results = $sn->get_records({
       active    => true,
       site_name => 'knoxfield',
       __limit   => 2,
       __columns => 'name,description'
       });
   # Sample result set:
   # $data_hr = {
   #   'count' => 2,
   #   'rows' => [
   #     {
   #       'description' => 'Knoxfield Main Site',
   #       'name' => 'KNX Main Office'
   #     },
   #     {
   #       'description' => 'Knoxfield Warehouse',
   #       'name' => 'KNX Warehouse'
   #     },
   #   ]
   # };

=head3 get_records CHUNKED

Should you require to extract a large amount of data you can employ a callback function
to handle the response records and define a suitable chunk size (depending on your system/network/...).
If you define a callback function, you can define your chunk size using __chunks (default is 250)
and the maximum record count to return (using __max_records).  You can also define a sleep period
in seconds between each chunk, should you wish to limit your impact on the system.

Example:

 __max_records    => 10000,            # Return at maximum 10000 records
 __chunks         => 300,              # Get 300 records at a time
 __callback       => \&write_csv,      # Call your function write_csv
 __callback_sleep => 1,                # Sleep for a second between chunks

The callback function will be passed the following arguments:

=over 4

=item $results

The data set hash (as per a normal return value from get_records(), which may be undef for no more records.

=item $first_call

Flag, if true, indicates the first callback for the data set.

=item $headers

The field headers expected in $results->{rows}, as an array ref (ie based on what we have in __columns or all columns).
Note that if __plus_display_value is true, you will also get a dv_<fieldname> for each return field.
This array can be used to select the data, print a header, act as keys to set headers from a hash, ....

=back

=head3 get_records chunked EXAMPLE

 # get_records CHUNKED
 #
 #
 use warnings;
 use strict;
 use ServiceNow::Simple;
 use Text::CSV;
 use feature 'state';
 use Data::Dumper;

 my $sn = ServiceNow::Simple->new({
     instance              => 'demo012',
     user                  => 'admin',
     password              => 'admin',
     table                 => 'sys_user',
     __encoded_query       => 'user_nameSTARTSWITHa',
     });
 $sn->set_plus_display_value(1);
 my $results = $sn->get_records({
     __columns            => 'name,user_name,dv_department,department',
     __max_records        => 92,
     __chunks             => 10,
     __callback           => \&write_csv,
     });

 print Dumper($results), "\n";

 sub write_csv
 {
     my (
         $results,       # The data set hash, which may be undef for no more records
         $first_call,    # Flag to indicate first callback for data set, if true
         $headers        # The field headers expected in $results->{rows}, as an array ref (ie based on what we have in __columns or all columns)
         ) = @_;

     # Text::CSV object
     state $csv;
     state $fh;
     state $total_rows = 0;

     # Do initialisation if first_call
     if ($first_call)
     {
         $csv = Text::CSV->new({ binary => 1, eol => "\015\012" }) or die "Cannot use CSV: ".Text::CSV->error_diag ();
         open($fh, ">:encoding(utf8)", "new.csv") or die "new.csv: $!";
         $csv->print($fh, $headers);
     }

     # Print the row from results in the order of headers
     if ($results && $results->{count})
     {
         foreach my $row (@{ $results->{rows} })
         {
             my @data = @{$row}{@$headers};  # Hash slice
             $csv->print($fh, \@data);
             $total_rows++;
         }
     }
     else
     {
         close $fh or die "new.csv: $!";
         print "Wrote $total_rows rows to new.csv\n";
     }
 }


=head2 add_attachment

Add a attachment (file) to a record in a table.

Example:

 $result = $sn->add_attachment({
             file_name => '/tmp/my_sample.xls',
             table     => 'incident',
             sys_id    => '97415d1f1903ac00fb54adb1ad53dc1a',
             });

=head2 insert

Creates a new record for the table.  B<Note:> You need to provide all fields configured
as mandatory (these are reflected in the WSDL as fileds with the attribute minOccurs=1).
Example:

  $sn->set_table('sys_user');
  my $result = $sn->insert({
      user_name => 'GNG',
      name      => 'GNG Test Record',
      active    => 'true',
  });
  print Dumper($result), "\n";
  # Sample success result:
  # $VAR1 = {
  #   'name' => 'GNG Test Record',
  #   'sys_id' => '2310f10bb8d4197740ff0d351492f271'
  # };

=head2 update

Updates an existing record in the targeted table, identified by the mandatory sys_id field.
Example:

  my $r = $sn->update({
      sys_id => '97415d1f1903ac00fb54adb1ad54dc1a',    ## REQUIRED, sys_id must be provided
      active => 'true',                                #  Other field(s)
      });

  $r will be the sys_id, unless there is a fault, in which case it is undef and $self->{__fault}
  will be set as follows:

  $self->{__fault}{faultcode}
  $self->{__fault}{faultstring}
  $self->{__fault}{detail}

=head1 RELATED METHODS

Allow you to change tables, instances, debug messages, printing etc

=head2 print_results

If called without an argument, returns the current value.  Called with
a true value sets printing of results using Data::Dumper's Dump method.
Will also log to the log file if __log object is defined.

=head2 set_instance

Allows the instance to be changed from what was defined in the call to new.
B<Note:> This assumes the format of the URL is:

 instance.service-now.com

if this is not the case (it normally is) you should be using I<instance_url> instead.

=head2 set_instance_url

Allows the instance URL to be changed from what was defined in the call to new.
B<Note:> This assumes the format of the URL is:

 https://something/

B<You would normally use 'instance' rather than 'instance_url'>.
I<instance_url> takes precedence over I<instance>.

=head2 set_table

Define the table the next method will work with/on.  Example:

 $sn->set_table('sys_user');
 # query something on User table
 #...
 $sn->set_table('cmn_locations');
 # Now query something on Locations table

=head2 soap_debug

Turn on or off soap debug messages.  Example:

 $sn->soap_debug(1); # Turn on debugging
 # do some stuff
 $sn->soap_debug(0); # Turn off debugging
 # do some more stuff


=head2 set_display_value

Affects what is returned for a reference field.  By default a reference field
returns the sys_id of the field referenced.  Turning on set_display_value will
change this to return the display value for that table.  Example:

 $sn->set_display_value(1);  # Turn on 'display value'
 $sn->set_display_value(0);  # Turn off 'display value', so sys_id is returned

=head2 set_plus_display_value

Affects what is returned for a reference field.  By default a reference field
returns the sys_id of the field referenced.  Turning on set_plus_display_value will
return two fields for reference field(s), one prefixed with I<dv_> which has the
display value for that table and the original reference field(s) which will contain
the sys_id.  Example:

 $sn->set_plus_display_value(1);  # Turn on 'display value & reference value'
 $sn->set_plus_display_value(0);  # Turn off 'display value & reference value', so sys_id is returned

=head1 PRIVATE METHODS

Internal, you should not use, methods.  They may change without notice.

=head2 set_soap

=head2 SOAP::Transport::HTTP::Client::get_basic_credentials

=head2 _get_method

=head2 _init

=head2 _load_args

=head2 _load_wsdl

=head2 _print_fault

=head1 USEFUL LINKS

 http://wiki.servicenow.com/index.php?title=Direct_Web_Services

 http://wiki.servicenow.com/index.php?title=Direct_Web_Service_API_Functions

 A demo instance: https://demo019.service-now.com/

 Query building: http://wiki.servicenow.com/index.php?title=RSS_Feed_Generator

=head1 OTHER FIELD ARGUMENTS

=head2 __encoded_query

Specify an encoded query string to be used in filtering the returned results.
The encoded query string format is similar to the value that may be specified
in a sysparm_query URL parameter.  Example:

 __encoded_query => 'active=true^nameSTARTSWITHa'

=head2 __order_by

Determines what fields the results are ordered by (ascending order). Example:

 __order_by => 'active'

=head2 __order_by_desc

Order by in descending order.

=head2 __exclude_columns

Specify a list of comma delimited field names to exclude from the results.
This is, generally the opposite of what you want.  See __columns below.

=head2 __columns

Define the columns you want in the results as a comma delimited list.  Example:

 __columns => 'active,name,sys_id'

=head2 __limit

Limit the number of records that are returned.  The default is 250.  This can
be set in the constructor I<new()> in which case it is applied for all relavent
calls or use it in the method calls get_keys or get_records.  Example:

 __limit => 2000,  # Return up to 2000 records

=head2 __first_row

Instruct the results to be offset by this number of records, from the beginning of the set.
When used with __last_row has the effect of querying for a window of results.
The results are inclusive of the first row number.

Note, do not use __limit with __first_row/__last_row otherwise the system will generate a
result set based on __limit rather than what is required for __first_row/__last_row.

=head2 __last_row

Instruct the results to be limited by this number of records, from the beginning of the set,
or the __start_row value when specified. When used with __first_row has the effect
of querying for a window of results. The results are less than the last row number,
and does not include the last row.  See __limit comment above for __first_row.

=head2 __use_view

Specify a Form view by name, to be used for limiting and expanding the results returned.
When the form view contains deep referenced fields eg. caller_id.email, this field will
be returned in the result as well

=head1 FILES

=head2 config.cache

Used to provide user, password and proxy settings for tests in /t

=head2 Simple.cfg

A configuration file that can contain the default user, password and proxy to use for all calls
to method new() unless the 'user', 'password' and 'proxy' arguments are provided.  The user and
password are obfuscated.  This is a very useful feature, only one place to change the user and
password and they are not visible in a whole bunch of scripts.

=head1 VERSION

Version 0.10

=cut

=head1 AUTHOR

Greg George, C<< <gng at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ServiceNow::Simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ServiceNow::Simple>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ServiceNow::Simple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ServiceNow::Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ServiceNow::Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ServiceNow::Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/ServiceNow::Simple/>

=back


=head1 ACKNOWLEDGEMENTS

Jay K. Slay for assistance in debugging in a proxy environment

The ServiceNow Wiki (see useful links), and authors of SOAP::Lite:

 Paul Kulchenko (paulclinger@yahoo.com)
 Randy J. Ray   (rjray@blackperl.com)
 Byrne Reese    (byrne@majordojo.com)
 Martin Kutter  (martin.kutter@fen-net.de)
 Fred Moyer     (fred@redhotpenguin.com)

John Andersen for suggesting instance_url
 see http://community.servicenow.com/forum/20300#comment-44864

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Greg George.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

# End of ServiceNow::Simple

#---< End of File >---#

package Net::DNS::SPF::Expander;
$Net::DNS::SPF::Expander::VERSION = '0.021';
use Moo;
use MooX::Options;
use Types::Standard qw/Str HashRef ArrayRef Maybe Int InstanceOf RegexpRef/;
use Net::DNS::ZoneFile;
use Net::DNS::Resolver;
use Path::Tiny;
use List::AllUtils qw(sum any part first uniq);
use Scalar::Util ();

# ABSTRACT: Expands DNS SPF records, so you don't have to.
# The problem is that you only get 10 per SPF records,
# and recursions count against you. Your record won't
# validate.

=head1 NAME

Net::DNS::SPF::Expander

=head1 DESCRIPTION

This module expands DNS SPF records, so you don't have to.
The problem is that you only get 10 per SPF record,
and recursions count against you. Your record won't
validate.

Let's say you start with this as an SPF record:

    @   TXT   "v=spf1 include:_spf.google.com include:sendgrid.net a:hq1.campusexplorer.com a:hq2.campusexplorer.com a:mail2.campusexplorer.com ~all"

You go to http://www.kitterman.com/spf/validate.html and check this record.
It passes validation. But later you come back and add salesforce, so that you
now have:

    @   TXT   "v=spf1 include:_spf.google.com include:sendgrid.net include:salesforce.com a:hq1.campusexplorer.com a:hq2.campusexplorer.com a:mail2.campusexplorer.com ~all"

And now your record fails validation.

    _spf.google.com takes 3 lookups.
        _spf1.google.com
        _spf2.google.com
        _spf3.google.com
    sendgrid.net takes 1 lookup.
        _sendgrid.biz
    hq1 takes 1 lookup.
    hq2 takes 1 lookup.
    mail2 takes 1 lookup.

Salesforce adds:

    _spf.google.com (3 you already did)
        _spf1.google.com
        _spf2.google.com
        _spf3.google.com
    mx takes 4 lookups.
        salesforce.com.s8a1.psmtp.com.
        salesforce.com.s8a2.psmtp.com.
        salesforce.com.s8b1.psmtp.com.
        salesforce.com.s8b2.psmtp.com.

So now instead of 7 you have 14. The common advice is to
expand them, and that is a tedious process. It's especially
tedious when, say, salesforce changes their mx record.

So this module and the accompanying script attempt
to automate this process for you.

=head1 SYNOPSIS

Using the script:

    myhost:~/ $ dns-dpf-expander --input_file zone.db
    myhost:~/ $ ls
     zone.db   zone.db.new   zone.db.bak

Using the module:

    {
        package MyDNSExpander;

        use Net::DNS::SPF::Expander;

        my $input_file = '/home/me/project/etc/zone.db';
        my $expander = Net::DNS::SPF::Expander->new(
            input_file => $input_file
        );

        my $string = $expander->write;

        1;
    }

=head1 CONFIGURABLE ATTRIBUTES

=head2 input_file

This is the path and name of the zonefile whose SPF records you want
to expand. It must be a valid L<Net::DNS::Zonefile> zonefile.

=cut

option 'input_file' => (
    is       => 'ro',
    isa      => InstanceOf ["Path::Tiny"],
    coerce   => sub { path($_[0]) },
    required => 1,
    format   => 's',
    doc      => 'The file to be SPF-expanded'
);

=head2 output_file

The path and name of the output file. By default, we tack ".new"
onto the end of the original filename.

=cut

option 'output_file' => (
    is      => 'ro',
    isa     => InstanceOf ["Path::Tiny"],
    coerce  => sub { path($_[0]) },
    lazy    => 1,
    builder => '_build_output_file',
    format  => 's',
    doc     => 'The destination file to write SPF-expanded records'
);

=head2 backup_file

The path and name of the backup file. By default, we tack ".bak"
onto the end of the original filename.

=cut

has 'backup_file' => (
    is         => 'ro',
    isa      => InstanceOf["Path::Tiny"],
    lazy       => 1,
    builder    => '_build_backup_file',
);

=head2 nameservers

A list of nameservers that will be passed to the resolver.

=cut

has 'nameservers' => (
    is  => 'ro',
    isa => Maybe[ArrayRef],
);

=head2 parsed_file

The L<Net::DNS::Zonefile> object created from the input_file.

=cut

has 'parsed_file' => (
    is         => 'ro',
    isa        => InstanceOf['Net::DNS::ZoneFile'],
    lazy       => 1,
    builder    => '_build_parsed_file',
);

=head2 to_expand

An arrayref of regexes that we will expand. By default we expand
a, mx, include, and redirect records. Configurable.

=cut

has 'to_expand' => (
    is      => 'ro',
    isa     => ArrayRef[RegexpRef],
    default => sub {
        [ qr/^a:/, qr/^mx/, qr/^include/, qr/^redirect/, ];
    },
);

=head2 to_copy

An arrayref of regexes that we will simply copy over. By default
we will copy ip4, ip6, ptr, and exists records. Configurable.

=cut

has 'to_copy' => (
    is      => 'rw',
    isa     => ArrayRef[RegexpRef],
    default => sub {
        [ qr/v=spf1/, qr/^ip4/, qr/^ip6/, qr/^ptr/, qr/^exists/, ];
    },
);

=head2 to_ignore

An arrayref of regexes that we will ignore. By default we ignore ?all,
exp, v=spf1, and ~all.

=cut

has 'to_ignore' => (
    is      => 'ro',
    isa     => ArrayRef[RegexpRef],
    default => sub {
        [ qr/^v=spf1/, qr/^(\??)all/, qr/^exp/, qr/^~all/ ];
    },
);

=head2 maximum_record_length

We leave out the protocol declaration and the trailing ~all
while we are expanding records, so we need to subtract their length
from our length calculation.

=cut

has 'maximum_record_length' => (
    is      => 'ro',
    isa     => Int,
    default => sub {
        255 - length('v=spf1 ') - length(' ~all') - length('"') - length('"');
    },
);

=head2 ttl

Default time to live is 10 minutes. Configurable.

=cut

has 'ttl' => (
    is      => 'ro',
    isa     => Str,
    default => sub { '10M' },
);

=head2 origin

The origin of the zonefile. We take it from the zonefile,
or you can set it if you like.

=cut

has 'origin' => (
    is         => 'ro',
    isa        => Str,
    lazy       => 1,
    builder    => '_build_origin',
);

=head1 PRIVATE ATTRIBUTES

=head2 _resource_records

An arrayref of all the L<Net::DNS::RR> resource records
found in the entire parsed_file.

=cut

has '_resource_records' => (
    is         => 'ro',
    isa        => Maybe[ArrayRef[InstanceOf["Net::DNS::RR"]]],
    lazy       => 1,
    builder    => '_build__resource_records',
);

=head2 _spf_records

An arrayref of the L<Net::DNS::RR::TXT> or L<Net::DNS::RR::SPF>
records found in the entire parsed_file.

=cut

has '_spf_records' => (
    is         => 'ro',
    isa        => Maybe[ArrayRef[InstanceOf["Net::DNS::RR"]]],
    lazy       => 1,
    builder    => '_build__spf_records',
);

=head2 _resolver

What we use to do the DNS lookups and expand the records. A
L<Net::DNS::Resolver> object. You can still set environment
variables if you want to change the nameserver it uses.

=cut

has '_resolver' => (
    is         => 'ro',
    isa        => InstanceOf["Net::DNS::Resolver"],
    lazy       => 1,
    builder    => '_build__resolver',
);

=head2 _expansions

This is a hashref representing the expanded SPF records. The keys
are the names of the SPF records, and the values are hashrefs.
Those are keyed on the include, and the values are arrayrefs of the
expanded values. There is also a key called "elements" which gathers
all the includes into one place, e.g.,

    "*.test_zone.com" => {
        "~all"   => undef,
        elements => [
            "ip4:216.239.32.0/19", "ip4:64.233.160.0/19",
            "ip4:66.249.80.0/20",  "ip4:72.14.192.0/18",
            ...
        ],
        "include:_spf.google.com" => [
             "ip4:216.239.32.0/19",
             "ip4:64.233.160.0/19",
             ...
        ],
        "ip4:96.43.144.0/20" => [ "ip4:96.43.144.0/20" ],
        "v=spf1"             => undef
      }

They are alpha sorted in the final results for predictability in tests.

=cut

has '_expansions' => (
    is         => 'ro',
    isa        => HashRef,
    lazy       => 1,
    builder    => '_build__expansions',
);

=head2 _lengths_of_expansions

We need to know how long the expanded record would be, because
SPF records should be less than 256 bytes. If the expanded
record would be longer than that, we need to split it into
pieces.

=cut

has '_lengths_of_expansions' => (
    is         => 'ro',
    isa        => HashRef,
    lazy       => 1,
    builder    => '_build__lengths_of_expansions',
);

=head2 _record_class

What sort of records are SPF records? IN records.

=cut

has '_record_class' => (
    is      => 'ro',
    isa     => Str,
    default => sub {
        'IN',;
    },
);

=head1 BUILDERS

=head2 _build_resolver

Return a L<Net::DNS::Resolver>. Any nameservers will be passed
through to the resolver.

=cut

sub _build__resolver {
    my $self        = shift;
    my $nameservers = $self->nameservers;
    my $resolver    = Net::DNS::Resolver->new(
        recurse => 1,
        ( $nameservers ? ( nameservers => $nameservers ) : () ),
    );
    return $resolver;
}

=head2 _build_origin

Extract the origin from parsed_file.

=cut

sub _build_origin {
    my $self = shift;
    return $self->parsed_file->origin;
}

=head2 _build_expansions

=cut

sub _build__expansions {
    my $self = shift;
    return $self->_expand;
}

=head2 _build_backup_file

Tack a ".bak" onto the end of the input_file.

=cut

sub _build_backup_file {
    my $self = shift;
    my $path = $self->input_file->parent;
    my $name = $self->input_file->basename;
    return path("${path}/${name}.bak");
}

=head2 _build_output_file

Tack a ".new" onto the end of the input_file.

=cut

sub _build_output_file {
    my $self = shift;
    my $path = $self->input_file->parent;
    my $name = $self->input_file->basename;
    return path("${path}/${name}.new");
}

=head2 _build_parsed_file

Turn the L<Path::Tiny> filehandle into a L<Net::DNS::Zonefile>
object, so that we can extract the SPF records.

=cut

sub _build_parsed_file {
    my $self = shift;
    my $path = $self->input_file->parent;
    my $name = $self->input_file->basename;
    return Net::DNS::ZoneFile->new("${path}/${name}");
}

=head2 _build_resource_records

Extract all the resource records from the L<Net::DNS::Zonefile>.

=cut

sub _build__resource_records {
    my $self             = shift;
    my @resource_records = $self->parsed_file->read;
    return \@resource_records;
}

=head2 _build__spf_records

Grep through the _resource_records to find the SPF
records. They can be both "TXT" and "SPF" records,
so we search for the protocol string, v=spf1.

=cut

sub _build__spf_records {
    my $self = shift;

    # This is crude but correct: SPF records can be both TXT and SPF.
    my @spf_records =
        grep { $_->txtdata =~ /v=spf1/ }
        grep { $_->can('txtdata') }
    @{ $self->_resource_records };
    return \@spf_records;
}

=head2 _build__lengths_of_expansions

Calculate the length of each fully expanded SPF record,
because they can't be longer than 256 bytes. We have to split them
up into multiple records if they are.

=cut

sub _build__lengths_of_expansions {
    my $self              = shift;
    my $expansions        = $self->_expansions;
    my $length_per_domain = {};
    for my $domain ( keys %$expansions ) {
        my $record_string = join(
            ' ',
            @{ $expansions->{$domain}{elements} }
        );
        $length_per_domain->{$domain} = length($record_string);
    }
    return $length_per_domain;
}

=head1 PUBLIC METHODS

=head2 write

This is the only method you really need to call. This expands all your SPF
records and writes out the new and the backup files.

Returns a scalar string of the data written to the file.

=cut

sub write {
    my $self  = shift;
    my @new_lines = @{$self->_new_records_lines};
    my @input_lines = $self->input_file->lines;
    $self->backup_file->spew(@input_lines);
    $self->output_file->spew(@new_lines);
    return join( '', @new_lines );
}

=head2 new_spf_records

In case you want to see how your records were expanded, this returns
the hashref of L<Net::DNS::RR> objects used to create the new records.

=cut

sub new_spf_records {
    my $self       = shift;
    my $lengths    = $self->_lengths_of_expansions;
    my $expansions = $self->_expansions;

    my %new_spf_records = ();

    for my $domain ( keys %$lengths ) {
        my $new_records = [];

        # We need to make sure the SPF record is less than 256 chars,
        # including the spf version and trailing ~all.
        if ( $lengths->{$domain} > $self->maximum_record_length ) {
            $new_records = $self->_new_records_from_partition(
                $domain,
                $expansions->{$domain}{elements},
            );
        } else {
            $new_records = $self->_new_records_from_arrayref(
                $domain,
                $expansions->{$domain}{elements},
            );
        }
        $new_spf_records{$domain} = $new_records;
    }
    return \%new_spf_records;
}

=head1 PRIVATE METHODS

=head2 _normalize_component

Each component of an SPF record has a prefix, like include:, mx:, etc.
Here we chop off the prefix before performing the lookup on the value.

=cut

sub _normalize_component {
    my ( $self, $component ) = @_;
    my $return = $component;
    $return =~ s/^.+?://g;
    return $return;
}

=head2 _perform_expansion

Expand a single SPF record component. This returns either undef or the
full SPF record string from L<Net::DNS::RR::TXT>->txtdata.

=cut

sub _perform_expansion {
    my ( $self, $component ) = @_;
    $component = $self->_normalize_component($component);
    my $packet = $self->_resolver->search( $component, 'TXT', 'IN' );
    return unless ($packet) && $packet->isa('Net::DNS::Packet');
    my ($answer) = $packet->answer;
    return unless ($answer) && $answer->isa('Net::DNS::RR::TXT');
    my $data = $answer->txtdata;
    return $data;
}

=head2 _expand_spf_component

Recursively call _perform_expansion for each component of the SPF record.
This returns an array consisting of the component, e.g., include:salesforce.com,
and an arrayref consisting of its full expansion, e.g.,

    [
        "ip4:216.239.32.0/19",
        "ip4:64.233.160.0/19",
        ...
        "ip6:2c0f:fb50:4000::/36"
    ]

=cut

sub _expand_spf_component {
    my ( $self, $component, $expansions ) = @_;

    $expansions ||= [];

    return unless $component;

    my @component_splits = split( ' ', $component );
    my $splits = @component_splits;
    if ( $splits > 1 ) {
        for my $component (@component_splits) {
            $self->_expand_spf_component( $component, $expansions );
        }
    } else {
        if (( any { $component =~ $_ } @{ $self->to_ignore } )) {
            return $component;
        } elsif (( any { $component =~ $_ } @{ $self->to_copy } )) {
            push @{$expansions}, $component;
        } elsif (( any { $component =~ $_ } @{ $self->to_expand } )) {
            my $new_component = $self->_perform_expansion($component);
            $self->_expand_spf_component( $new_component, $expansions );
        } else {
            return $component;
        }
    }
    return ( $component, $expansions );
}

=head2 _expand

Create the _expansions hashref from which we generate new SPF records.

=cut

sub _expand {
    my $self           = shift;
    my %spf_hash       = ();
    my %keys_to_delete = ();
    for my $spf_record ( @{ $self->_spf_records } ) {
        my @spf_components = split( ' ', $spf_record->txtdata );
        for my $spf_component (@spf_components) {
            my $component_name = $self->_normalize_component($spf_component);
            # We want to make sure that we do not look up spf records that are
            # defined in this zonefile. So that we could run this tool on a
            # previously expanded zonefile if we want to. That sort of defeats
            # the point of the tool, but you may edit the previously expanded zonefile,
            # adding a new include: or mx, appending it to the other _spfX includes.
            # We just take the component and its existing expansions and stick them
            # into the component's parent as a key and value, and then we remove that
            # component as a separate key from our hash.
            if ( any { $component_name eq $_->name } @{ $self->_spf_records } ) {
                my ($zonefile_record)
                    = grep { $component_name eq $_->name }
                    @{ $self->_spf_records };
                my ( $comp, $expansions )
                    = $self->_expand_spf_component(
                    $zonefile_record->txtdata );
                $spf_hash{ $spf_record->name }{$spf_component} = $expansions;
                $keys_to_delete{$component_name} = 1;
            # If the include or what have you is not defined in the zonefile,
            # proceed as normal.
            } else {
                my ( $comp, $expansions )
                    = $self->_expand_spf_component($spf_component);
                $spf_hash{ $spf_record->name }{$spf_component} = $expansions;
            }
        }
        my $expansion_elements = $self->_extract_expansion_elements(
            $spf_hash{ $spf_record->name } );
        $spf_hash{ $spf_record->name }{elements} = $expansion_elements;
    }
    delete @spf_hash{ keys %keys_to_delete };
    return \%spf_hash;
}

=head2 _extract_expansion_elements

Filter ignored elements from component expansions.

=cut

sub _extract_expansion_elements {
    my ( $self, $expansions ) = @_;
    my @elements = ();
    my @leading  = ();
    my @trailing = ();
KEY: for my $key ( keys %$expansions ) {
        if ( any { $key =~ $_ } @{ $self->to_ignore } ) {
            next KEY;
        }
        if ( ref( $expansions->{$key} ) eq 'ARRAY' ) {
            for my $expansion ( @{ $expansions->{$key} } ) {
                push @elements, $expansion;
            }
        }
    }
    # We sort these so we can be sure of the order in tests.
    my @return = uniq sort { $a cmp $b } ( @leading, @elements, @trailing );
    return \@return;
}

=head2 _new_records_from_arrayref

The full expansion of a given SPF record is contained in an arrayref,
and if the length of the resulting new SPF record would be less than the
maximum_record_length, we can use this method to make new
L<Net::DNS::RR> objects that will later be stringified for the new
SPF record.

=cut

sub _new_records_from_arrayref {
    my ( $self, $domain, $expansions ) = @_;

    my $txtdata = join(' ', @$expansions);

    my @new_records = ();
    push @new_records, new Net::DNS::RR(
        type    => 'TXT',
        name    => $domain,
        class   => $self->_record_class,
        ttl     => $self->ttl,
        txtdata => $txtdata,
    );
    return \@new_records;
}

=head2 _new_records_from_partition

The full expansion of a given SPF record is contained in an arrayref,
and if the length of the resulting new SPF record would be greater than the
maximum_record_length, we have to jump through some hoops to properly split
it into new SPF records. Because there will be more than one, and each needs
to be less than the maximum_record_length. We do our partitioning here, and
then call _new_records_from_arrayref on each of the resulting partitions.

=cut

sub _new_records_from_partition {
    my ( $self, $domain, $elements, $partitions_only ) = @_;
    my $record_string = join( ' ', @$elements );
    my $record_length = length($record_string);
    my $max_length    = $self->maximum_record_length;
    my $offset        = 0;
    my $result        = index( $record_string, ' ', $offset );
    my @space_indices = ();

    while ( $result != -1 ) {
        push @space_indices, $result if $result;
        $offset = $result + 1;
        $result = index( $record_string, ' ', $offset );
    }

    my $number_of_partitions = int($record_length / $max_length + 0.5)
        + ( ( $record_length % $max_length ) ? 1 : 0 );

    my @partitions       = ();
    my $partition_offset = 0;

    for my $part ( 1 .. $number_of_partitions ) {

        # We want the first space_index that is
        #   1. less than the max_length times the number of parts, and
        #   2. subtracting the partition_offset from it is less than
        #      max_length.
        my $split_point = first {
            ( $_ < ( $max_length * $part ) )
                && ( ( $_ - $partition_offset ) < $max_length )
        } reverse @space_indices;

        my $partition_length = $split_point - $partition_offset;

        # Go to the end of the string if we are dealing with
        # the last partition. Otherwise, the last element
        # gets chopped off, because it is after the last space_index!
        my $length
            = ( $part == $number_of_partitions ) ? undef : $partition_length;
        my $substring;
        if ( $part == $number_of_partitions ) {
            # Go to the end.
            $substring = substr( $record_string, $partition_offset );
        } else {
            # Take a specific length.
            $substring = substr( $record_string, $partition_offset,
                $partition_length );
        }

        push @partitions, [ split( ' ', $substring ) ];
        $partition_offset = $split_point;
    }
    return \@partitions if $partitions_only;

    my @return = ();

    for my $partition (@partitions) {
        my $result = $self->_new_records_from_arrayref( $domain, $partition );
        push @return, $result;
    }
    return \@return;
}

=head2 _get_single_record_string

Stringify the L<Net::DNS::RR::TXT> records when they will fit into
a single SPF record.

=cut

sub _get_single_record_string {
    my ( $self, $domain, $record_set ) = @_;
    my $origin = $self->origin;

    my @record_strings = ();

    my @sorted_record_set = map { $_ }
        sort  { $a->string cmp $b->string }
    @$record_set;

    for my $record (@sorted_record_set) {
        $record->name($domain);
        $record->txtdata( 'v=spf1 ' . $record->txtdata . ' ~all' );

        my $string = $self->_normalize_record_name( $record->string );
        push @record_strings, $string;
    }
    return \@record_strings;
}

=head2 _normalize_record_name

L<Net::DNS> uses fully qualified record names, so that new SPF records
will be named *.domain.com, and domain.com, instead of * and @. I prefer
the symbols. This code replaces the fully qualified record names with symbols.

=cut

sub _normalize_record_name {
    my ( $self, $record ) = @_;

    $record =~ /(.+?)\s/;
    my $original_name = $1;
    my $origin        = $self->origin;

    my $name;

    if ( $original_name =~ /^$origin(.?)$/ ) {
        $name = '@';
    } elsif ( $original_name =~ /^\.$/ ) {
        $name = '@';
    } elsif ( $original_name =~ /^\*/ ) {
        $name = '*';
    } else {
        $name = $original_name;
    }
    $record =~ s/\Q$original_name\E/$name/g;
    $record =~ s/\n//g;
    $record =~ s/(\(|\))//g;
    $record =~ s/\t\s/\t/g;
    $record =~ s/\s\t/\t/g;
    $record =~ s/\t\t/\t/g;
    $record =~ s/\t/    /g;
    $record =~ s/\s/ /g;
    $record = $record."\n";
    return $record;
}

=head2 _get_multiple_record_strings

Whereas a single new SPF record needs to be concatenated from
the stringified L<Net::DNS::RR::TXT>s, and have the trailing
~all added, multiple new SPF records do not need that. They need to be given
special _spf names that will then be included in "master" SPF records, and
they don't need the trailing ~all.

=cut

sub _get_multiple_record_strings {
    my ( $self, $values, $start_index ) = @_;
    my $origin = $self->origin;

    my @record_strings = ();

    my @containing_records = ();

    my $i = $start_index // 1;
    for my $value (@$values) {
        push @containing_records,
            new Net::DNS::RR(
                type    => 'TXT',
                name    => "_spf$i.$origin",
                class   => $self->_record_class,
                ttl     => $self->ttl,
                txtdata => 'v=spf1 ' . $value,
            );
        $i++;
    }

    @record_strings = map {
        $self->_normalize_record_name($_->string)
    } sort {
        $a->string cmp $b->string
    } @containing_records;

    return \@record_strings;
}

=head2 _get_master_record_strings

Create our "master" SPF records that include the split _spf records created
in _get_multiple_record_strings, e.g.,

    *    600    IN    TXT    "v=spf1 include:_spf1.test_zone.com include:_spf2.test_zone.com ~all"

=cut

sub _get_master_record_strings {
    my ( $self, $values, $domains ) = @_;

    (my $origin         = $self->origin) =~ s/\.$//g;
    my @record_strings = ();

    my @containing_records = ();

    my $master_records = [ map {"include:_spf$_.$origin"} ( 1 .. scalar(@$values)) ];
    my $master_record = join(' ', @$master_records);

    # If our master record will be too long, split it into multiple strings
    if (length($master_record) > $self->maximum_record_length) {

        my $new_master_record_partitions = $self->_new_records_from_partition(
            "master",
            $master_records,
            1, # Just return raw partitions
        );

        my @master_record_strings = ();
        my $i = 0;
        for my $partition (@$new_master_record_partitions) {
            my @master_record_partition = @$master_records[$i .. ($i + $#{$partition})];
            push @master_record_strings, join(' ', @master_record_partition);
            $i += scalar(@$partition);
        }
        $master_record_strings[0] = 'v=spf1 '. $master_record_strings[0];
        $master_record_strings[-1] = $master_record_strings[-1].' ~all';
        my $master_record_string = '';
        my $index = 0;
        for my $master_record (@master_record_strings) {
                $master_record = " ".$master_record unless $index == 0;
                $master_record_string .= qq|"$master_record"|;
                $index++;
        }

        for my $domain (@$domains) {

            push @containing_records,
            new Net::DNS::RR(
                type    => 'TXT',
                name    => $domain,
                class   => $self->_record_class,
                ttl     => $self->ttl,
                txtdata => \@master_record_strings,
            );
        }

    # Otherwise, proceed as normal
    } else {

        for my $domain (@$domains) {

            push @containing_records,
            new Net::DNS::RR(
                type    => 'TXT',
                name    => $domain,
                class   => $self->_record_class,
                ttl     => $self->ttl,
                txtdata => 'v=spf1 ' . (join(
                ' ',
                ( map {"include:_spf$_.$origin"} ( 1 .. scalar(@$values) ) )
                )) . ' ~all',
            );
        }

    }

    @record_strings = map {
        $self->_normalize_record_name($_->string)
    } sort {
        $a->string cmp $b->string
    } @containing_records;

    return \@record_strings;
}

=head2 _new_records_lines

Assemble the new DNS zonefile from the lines of the original,
comment out the old SPF records, add in the new lines, and append the
end of the original.

=cut

sub _new_records_lines {
    my $self           = shift;
    my %new_records    = %{ $self->new_spf_records || {} };
    my @record_strings = ();

    # Make a list of the unique records in case we need it.
    my @autosplit = ();
    for my $domain ( keys %new_records ) {
        for my $record_set ( @{ $new_records{$domain} } ) {
            if ( ref($record_set) eq 'ARRAY' ) {
                for my $record (@$record_set) {
                    push @autosplit, $record->txtdata;
                }
            } else {
                push @autosplit, $record_set->txtdata;
            }
        }
    }
    @autosplit = uniq @autosplit;

    # If there are any autosplit SPF records, we just do that right away.
    # This test is kind of nasty.
    my $make_autosplit_records = grep {
        defined( ${ $new_records{$_} }[0] )
            && ref( ${ $new_records{$_} }[0] ) eq 'ARRAY'
    } sort keys %new_records;
    if ($make_autosplit_records) {
        my $master_record_strings
            = $self->_get_master_record_strings( \@autosplit,
            [ keys %new_records ] );
        my $record_strings
            = $self->_get_multiple_record_strings( \@autosplit );
        push @record_strings, @$master_record_strings;
        push @record_strings, @$record_strings;
    } else {
        for my $domain ( sort keys %new_records ) {
            my $record_string = $self->_get_single_record_string(
                $domain,
                $new_records{$domain},
            );
            push @record_strings, @$record_string;
        }
    }
    my @original_lines = $self->input_file->lines;
    my @new_lines      = ();
    my @spf_indices;
    my $i = 0;
LINE: for my $line (@original_lines) {
        if ( $line =~ /^[^;].+?v=spf1/ ) {
            push @spf_indices, $i;
            $line = ";" . $line;
        }
        push @new_lines, $line;
        $i++;
    }
    my @first_segment = @new_lines[ 0 .. $spf_indices[-1] ];
    my @last_segment  = @new_lines[ $spf_indices[-1] + 1 .. $#new_lines ];
    my @final_lines   = ( @first_segment, @record_strings, @last_segment );

    for my $line (@final_lines) {
        $line =~ s/\t/    /g;
        $line =~ s/\n\s+/\n/g;
        $line =~ s/\s+\n/\n/g;
        $line =~ s/\n+/\n/g;
    }
    return \@final_lines;
}

__PACKAGE__->meta->make_immutable;
__PACKAGE__->new_with_options->run unless caller;

1;

__END__

=head1 AUTHOR

Amiri Barksdale E<lt>amiri@campusexplorer.comE<gt>

=head2 CONTRIBUTORS

Neil Bowers E<lt>neil@bowers.comE<gt>

Marc Bradshaw E<lt>marc@marcbradshaw.netE<gt>

Karen Etheridge E<lt>ether@cpan.orgE<gt>

Chris Weyl E<lt>cweyl@campusexplorer.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2019 Campus Explorer, Inc.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::DNS>

L<Net::DNS::RR::TXT>

L<MooseX::Getopt>

=cut

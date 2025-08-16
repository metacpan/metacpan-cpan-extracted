package Net::Respite::CommandLine;

=head1 NAME

Net::Respite::CommandLine - Provide an easy way to get commandline abstraction of Net::Respite::Base

=cut

use strict;
use warnings;
use Throw qw(throw);
use Scalar::Util qw(blessed);

sub new {
    my ($class, $args) = @_;
    return bless {%{$args || {}}}, $class;
}

sub api_meta { shift->{'api_meta'} }
sub dispatch_class { shift->{'dispatch_class'} }

sub dispatch_factory { # this is identical to code in Net::Respite::Server
    my ($self, $preload) = @_;
    return $self->{'dispatch_factory'} ||= do {
        my $meta = $self->api_meta || $self->dispatch_class || throw "Missing one of api_meta or dispatch_class";
        if (!ref $meta) {
            (my $file = "$meta.pm") =~ s|::|/|g;
            throw "Failed to load dispatch class", {class => $meta, file => $file, msg => $@} if !$meta->can('new') && !eval { require $file };
            throw "Specified class does not have a run_method method", {class => $meta} if ! $meta->can('run_method');
            sub { $meta->new(@_) };
        } elsif ($meta->{'remote'}) {
            require Net::Respite::Client;
            sub { Net::Respite::Client->new({%{shift() || {}}, %$meta}) };
        } else {
            require Net::Respite::Base;
            Net::Respite::Base->new({api_meta => $meta})->api_preload if $preload;
            sub { Net::Respite::Base->new({%{shift() || {}}, api_meta => $meta}) };
        }
    };
}

###----------------------------------------------------------------###

sub run_commandline { shift->run(@_) }

sub run {
    my ($self, $args) = @_;
    $self = $self->new($args) if ! ref($self);

    my $obj = $self->dispatch_factory->();
    my $ARGV = $args->{'argv'} || $self->{'argv'} || \@ARGV;

    my $method = shift(@$ARGV) || return print $self->_pod($obj, {brief => 1});
    return print $self->_pod($obj, {format => $1}) if $method =~ /^-{0,2}(help|h|pod|p)$/;
    return print $self->_pod($obj, {method => $method, format => $_}) for grep {/^-{1,2}(help|h|pod|p)$/} @ARGV;

    throw "Odd number of args passed to commandline. If you want the last value to be undef pass a :null", {argv => $ARGV, _pretty=>1} if @$ARGV % 2;
    my $req = {@$ARGV};
    throw "Cannot use '' as a keyname - possible invalid args", {argv => $ARGV} if exists $req->{''};
    foreach my $key (keys %$req) { $req->{$key} = __PACKAGE__->can("_$1")->() if $req->{$key} && $req->{$key} =~ /^:(null|true|false)$/ }
    $req = Data::URIEncode::flat_to_complex($req) || {} if !$self->{'no_data_uriencode'} && eval { require Data::URIEncode };

    my $data = $self->_run_method($obj,$method, $req);
    my $meta = $ENV{'SHOW_META'} ? $self->_run_method($obj,"${method}__meta", $req) : undef;
    $self->print_data($data, $req, $meta);
    exit(1) if ref($data) && $data->{'error'};
}

sub run_method {
    my ($self, $method, $args) = @_;
    $self = $self->new($args) if ! ref($self);
    my $obj = $self->dispatch_factory->();
    return $self->_run_method($obj, $method, $args);
}

sub _run_method {
    my ($self, $obj, $method, $args, $extra) = @_;

    local $args->{'_c'} = ['commandline'] if $obj->can('config') ? !$obj->config(no_trace => undef) : 1;

    local $obj->{'remote_ip'}   = local $obj->{'api_ip'} = ($ENV{'REALUSER'} || $ENV{'SUDO_USER'}) ? 'sudo' : 'cmdline';
    local $obj->{'api_brand'}   = $ENV{'BRAND'} || $ENV{'PROV'} if $obj->isa('Net::Respite::Base') && ($ENV{'BRAND'} || $ENV{'PROV'});
    local $obj->{'remote_user'} = $ENV{'REALUSER'} || $ENV{'SUDO_USER'} || $ENV{'REMOTE_USER'} || $ENV{'USER'} || (getpwuid($<))[0] || '-unknown-';
    local $obj->{'token'}       = $self->{'token'} || $ENV{'ADMIN_Respite_TOKEN'} if $self->{'token'} || $ENV{'ADMIN_Respite_TOKEN'};
    local $obj->{'transport'}   = 'cmdline';
    $obj->commandline_init($method, $args, $self) if $obj->can('commandline_init');

    my $run = sub {
        my $data = eval { $obj->can('run_method') ? $obj->run_method(@_) : $obj->$method($args, ($extra ? $extra : ())) };
        $data = $@ if ! ref $data;
        return !ref($data) ? {error => 'Commandline failed', msg => $data} : (blessed($data) && $data->can('data')) ? $data->data : $data;
    };
    my $ref = $run->($method, $args, $extra);
    while ($ref->{'error'}) {
        last if !$ref->{'type'} || $ref->{'type'} !~ /^token_\w+$/;
        last if $self->{'no_token_retry'};
        warn "Prompting for authorization and retry ($ref->{'type'}: $ref->{'error'})\n";
        eval { require IO::Prompt } || throw "Please install IO::Prompt to authenticate from commandline", {msg => $@};
        my $user = ''.IO::Prompt::prompt("  Web Auth Username: ", -d => $obj->{'remote_user'}) || $obj->{'remote_user'};
        my $pass = ''.IO::Prompt::prompt("  Web Auth Password ($user): ", -e => '*') || throw "Cannot proceed without password";
        my $key  = !$obj->can('config') ? $config::config{'plaintext_public_key'}
            : $obj->config(plaintext_public_key => sub { $obj->config(plaintext_public_key => sub { $obj->_configs->{'plaintext_public_key'} }, 'emp_auth') });
        if (!$key) {
            warn "  Could not find plaintext_public_key in config - sending plaintext password\n";
        } elsif (!eval { require Crypt::OpenSSL::RSA }) {
            warn "  (Crypt::OpenSSL::RSA is not installed - install to avoid sending plaintext password)\n";
        } else {
            my $c = Crypt::OpenSSL::RSA->new_public_key($key);
            my $len = length($pass) + 1;
            $pass = pack 'u*', $c->encrypt(pack "Z$len", $pass);
            $pass = "RSA".length($pass).":$pass";
        }
        $obj->{'token'} = "$user/i:cmdline/$pass";
        $ref = $run->(hello => {test_auth => 1});
        $self->{'token'} = $obj->{'token'} = $ref->{'token'} || throw "Did not get a token back from successful test_auth", {data => $ref};
        warn "\nexport ADMIN_Respite_TOKEN=$obj->{'token'}\n\n";
        $ref = $run->($method, $args, $extra);
    }
    return $ref;
}

sub print_data {
    my ($self, $data, $args, $meta) = @_;
    if ($ENV{'CSV'} and my @fields = grep {ref($data->{$_}) eq 'ARRAY' && ref($data->{$_}->[0]) eq 'HASH'} sort keys %$data) {
        require Text::CSV_XS;
        my $csv = Text::CSV_XS->new({eol => "\n"});
        foreach my $field (@fields) {
            print "----- $field -------------------------\n" if @fields > 1;
            my @keys = sort {($a eq 'id') ? -1 : ($b eq 'id') ? 1 : $a cmp $b } keys %{ $data->{'rows'}->[0] };
            $csv->print(\*STDOUT, \@keys);
            $csv->print(\*STDOUT, [map {ref($_) eq 'ARRAY' ? join(",",@$_) : ref($_) eq 'HASH' ? join(",",%$_) : $_} @$_{@keys}]) for @{ $data->{'rows'} };
        }
        exit;
    }
    if ($ENV{'YAML'}) {
        eval { require YAML } || throw "Could not load YAML for output", {msg => $@};
        print YAML->new->Dump($data);
    } elsif ($ENV{'JSON'} || ! eval { require Text::PrettyTable }) {
        eval { require JSON } || throw "Could not load JSON for output", {msg => $@};
        my $json = JSON->new->utf8->allow_nonref->convert_blessed->pretty->canonical;
        print "meta = ".$json->encode($meta) if $ENV{'SHOW_META'};
        print "args = ".$json->encode($args);
        print "data = ".$json->encode($data);
    } elsif ($ENV{'PERL'}) {
        if (eval { require Data::Debug }) {
             Data::Debug::debug($args, $data);
        } else {
            require Data::Dumper;
            print Data::Dumper::Dumper($_) for $ENV{'SHOW_META'} ? $meta : (), $args, $data;
        }
    } else {
        my $p = PrettyTable->new({auto_collapse => 1});
        if ($ENV{'SHOW_META'}) {
            print "Meta:\n";
            print $p->tablify($meta);
        }
        print "Arguments:\n";
        print $p->tablify($args);
        if ((scalar(keys %$data) == 1 || $data->{'n_pages'} && $data->{'n_pages'} == 1) && $data->{'rows'}) {
            print "Data Rows:\n";
            print $p->tablify($data->{'rows'});
        } else {
            print "Data:\n";
            print $p->tablify($data);
        }
    }
}

sub _false { require JSON; JSON::false() }
sub _null  { undef }
sub _true  { require JSON; JSON::true() }

sub _pod {
    my ($self, $obj, $args) = @_;
    my $class = ref($obj);
    my $script = $args->{'script'} || $0;
    my $meth   = $args->{'method'} || 'methodname';
    my $out = "=head1 NAME\n\n"
        ."$script - commandline interface to $class methods\n\n"
        ."=head1 SYNOPSIS\n\n"
        ."    $script $meth\n\n"
        ."    $script $meth --help\n\n"
        ."    $script $meth methods   # brief list of methods \n\n"
        ."    $script $meth key1 value1 key2 value2\n\n"
        ."    $script $meth key1:0 arrayvalue1 key1:1 arrayvalue2\n\n"
        ."    JSON=1 $script $meth key1 value1 key2 value2\n\n"
        ."    YAML=1 $script $meth key1 value1 key2 value2\n\n"
        ."    PERL=1 $script $meth key1 value1 key2 value2\n\n"
        ."    CSV=1 $script $meth key1 value1 key2 value2 (only works for fields that are arrays of hashes)\n\n"
        ."    SHOW_META=1 $script $meth key1 value1 key2 value2 (includes meta information for $meth)\n\n"
        ."Arguments for the hashref should be passed on the commandline as"
        ." simple key value pairs.  If the arguments are more complex, you can"
        ." pass values in any of the ways that L<Data::URIEncode> supports.\n\n"
        ."=head1 METHODS\n\n";
    if ($args->{'brief'}) {
        $out .= join(", ", sort keys %{ $self->_run_method($obj, methods => {})->{'methods'} })."\n\n";
    } else {
        my $methods = ($_ = $args->{'method'}) ? {$_ => $self->_run_method($obj, "${_}__meta", {_flat => 1})} : $self->_run_method($obj, methods => {meta => 1, _flat => 1})->{'methods'};
        foreach my $meth (sort keys %$methods) {
            my $m = $methods->{$meth};
            $out .= "=head2 C<$meth>\n\n";
            $out .= "$m->{'desc'}\n\n" if $m->{'desc'};
            $out .= "=over 4\n\n";
            my $args = $m->{'args'}; my %uk;
            foreach my $field (grep {!$uk{$_}++} (map {split /\s*,\s*/} ref($args->{'group order'}) ? @{$args->{'group order'}} : $args->{'group order'}||()), grep {!/^group /} sort keys %$args) {
                $out .= "=item C<$field>\n\n";
                Data::Debug::debug($meth, $field, $args->{$field}) if ! ref($args->{$field}) && eval {require Data::Debug};
                $out .= "(required)\n\n" if $args->{$field}->{'required'};
                $out .= "$args->{$field}->{'desc'}\n\n" if $args->{$field}->{'desc'};
            }
            $out .= "=back\n\n";
        }
    }
    $out .= "=cut\n";
    if (!$args->{'format'} || ($args->{'format'} && $args->{'format'} =~ /h/)) {
        require Pod::Text;
        require IO::String;
        my $cols = $ENV{'COLUMNS'} || eval {
                                        require IO::Interactive;
                                        die if ! IO::Interactive::is_interactive(*STDOUT);
                                        require Term::ReadKey; (Term::ReadKey::GetTerminalSize(\*STDOUT))[0]
                                      } || 80;
        Pod::Text->new(width => $cols)->parse_from_file(IO::String->new($out), IO::String->new(my $txt));
        return $txt;
    }
    return $out;
}

1;

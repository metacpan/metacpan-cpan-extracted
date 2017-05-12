package Selenese;

# Copyright 2016, Paul Johnson (paul@pjcj.net) http://www.pjcj.net

# This software is free.  It is licensed under the same terms as Perl itself.

use 5.18.2;
use warnings;

use Data::Dumper;
use JavaScript::V8;
use Test::More;

$Data::Dumper::Indent   = 1;
$Data::Dumper::Purity   = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Deparse  = 1;

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    $self->init;
    $self
}

sub verbose { shift->{verbose}                             }
sub driver  { shift->{driver} // die "No driver specified" }

sub parse_loc {
    my $self = shift;
    my ($loc) = @_;
    $loc =~ /^(\w+)=(.*)/ ? ($1, $2) : ()
}

sub parse_loc_with_default {
    my $self = shift;
    my ($loc) = @_;
    $loc =~ /^(\w+)=(.*)/ ? ($1, $2) : ("xpath", $loc)
}

sub init {
    my $self = shift;

    my $vars = $self->{vars} //= {};

    my $dvr = "Selenium::" . $self->driver;
    eval "require $dvr";
    my $opts = {
        accept_ssl_certs => 1,
        %{$self->{driver_options} // {}}
    };
    say "Using $dvr" if $self->verbose;
    my $d = $self->{d} = $dvr->new(%$opts);

    $self->{init}->($d) if $self->{init};

    my $v8 = $self->{v8} = JavaScript::V8::Context->new();
    $v8->bind_function(say => sub { say "js: ", Dumper(@_) if $self->verbose });

    $v8->eval("var storedVars = {}");
    for my $var (keys %$vars) {
        my $js = "storedVars['$var'] = '$vars->{$var}'";
        $v8->eval($js);
    }
    $v8->eval("say(storedVars)");

    my $cmds = $self->{cmds} = {
        storeEval => sub {
            my ($expr, $key) = @_;
            return if $expr =~ /^prompt\(/;
            $vars->{$key} = $v8->eval("storedVars['$key'] = $expr");
            note "Setting $key to $vars->{$key} from $expr" if $self->verbose;
        },
        _eval => sub {
            my ($script) = @_;
            my $res = $v8->eval($script);
            note "Eval of [$script] => [" . ($res // "*undef*") . "]"
                if $self->verbose;
            $res
        },
        getEval => sub {
            my ($script) = @_;
            $self->{cmds}{_eval}->($script);
        },
        storeText => sub {
            my ($loc, $key) = @_;
            $vars->{$key} = $d->get_text($loc);
            note "Setting $key to $vars->{$key} from $loc" if $self->verbose;
        },
        open => sub {
            my ($loc) = @_;
            if (my ($scheme, $target) = $self->parse_loc($loc)) {
                die "Can't handle", $loc;
            } else {
                $d->get($loc);
            }
        },
        clickAndWait => sub {
            my ($loc) = @_;
            if (my ($scheme, $target) = $self->parse_loc_with_default($loc)) {
                $d->find_element($target, $scheme)->click;
            } else {
                die "Can't handle", $loc;
            }
        },
        type => sub {
            my ($loc, $text) = @_;
            if (my ($scheme, $target) = $self->parse_loc_with_default($loc)) {
                my $e = $d->find_element($target, $scheme);
                $e->clear;
                $e->send_keys($text);
            } else {
                die "Can't handle", $loc;
            }
        },
        select => sub {
            my ($select, $option) = @_;
            my ($sid, $s) = $self->parse_loc_with_default($select);
            my ($oid, $o) = $self->parse_loc_with_default($option);
            if (grep defined, $sid, $s, $oid, $o) {
                my $opt = ($oid eq "label" ? "normalize-space(.)" : "\@$oid");
                if (my ($re) = $o =~ /^regexp:(.*)/) {
                    $re = qr|$re|;
                    my $f = "//select[\@$sid='$s']";
                    $o = "";
                    my $select = $d->find_element($f);
                    my @children = $d->find_child_elements($select, "./option");
                    for my $e (@children) {
                        my $val = ($oid eq "label") ? $e->get_text
                                                    : $e->get_tag_name;
                        next unless $val =~ $re;
                        $o = $val;
                        s/^\s+//, s/\s+$//, s/\s+/ / for $o;
                        last;
                    }
                    die "Can't find element matching", "[$re]" unless $o;
                }
                $opt .= "='$o'";
                my $f = "//select[\@$sid='$s']/option[$opt]";
                my $e = $d->find_element($f);
                $e->click;
            } else {
                die "Can't handle", $select, $option;
            }
        },
        setTimeout => sub {
            my ($ms) = @_;
            $ms /= 10;  # hmmm
            $d->set_timeout("script",    $ms);
            $d->set_timeout("implicit",  $ms);
            $d->set_timeout("page load", $ms);
        },
        deleteAllVisibleCookies => sub {
            $d->delete_all_cookies;
        },
        selectWindow => sub {
        },
        quit => sub {
            $d->quit;
        },
    };

    $cmds->{click} = $cmds->{clickAndWait};
    $cmds->{addSelection} = $cmds->{select};
}

sub run_command {
    my $self = shift;
    my ($cmd, @params) = @_;

    say "command: $cmd(", join (", ", @params), ")" if $self->verbose;
    my $sub = $self->{cmds}{$cmd} or die "Can't handle $cmd @params";
    s/\$\{(\w+)\}/$self->{vars}{$1}/g for @params;
    my $ret = eval { $sub->(@params) };
    my $err = $@;
    ok !$err, "$cmd @params";
    BAIL_OUT("Exiting") if $err;
    $ret
}

"
Careful, now!
"

__END__

=head1 NAME

Selenese - Run Selenium IDE tests without the IDE

=head1 SYNOPSIS

 selenese

=head1 DESCRIPTION

This module allows you to run Selenium IDE tests without the IDE.

This makes your Selenium IDE tests useful for general testing purposes.  For
example, they could be used in a headless Continuous Integration environment.

=head1 REQUIREMENTS

=over

=item * Perl 5.18.2 or greater

This is probably not a hard requirement, but I've not thought much about earlier
versions.

=item * V8

On debian and ubuntu this requirement can be satisfied by installing the module
libv8-dev.

=back

=head1 OPTIONS

=head1 ENVIRONMENT

=head1 SEE ALSO

=head1 BUGS

=head1 LICENCE

Copyright 2016, Paul Johnson (paul@pjcj.net) http://www.pjcj.net

This software is free.  It is licensed under the same terms as Perl itself.

=cut

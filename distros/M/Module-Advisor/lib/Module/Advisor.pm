package Module::Advisor;
use strict;
use warnings;
use 5.008008;
our $VERSION = '0.17';
use Module::Metadata;
use CPAN::Meta::Requirements;
use Carp;

our @SECURITY = (
    ['Digest' => '< 1.17', 'have a security issue. which could lead to the injection of arbitrary Perl code'],
    ['Encode' => '< 2.44', 'heap overflow'],
    ['Encode' => '< 2.49', 'memory leaks'],
);

our @PERFORMANCE = (
    ['UNIVERSAL::require', '< 0.11', 'is 400% faster'],
);

our @BUG = (
    ['Plack' => '< 0.9982', 'sanity check to remove newlines from headers'],
    ['Time::Piece' => '< 1.16', 'have timezone related issue'],
    ['DBD::SQLite' => '< 1.20', 'a lot of bugs.'],
    ['Mouse' => '>= 1.07, < 1.12', 'Memory leaks in trigger'],
    ['Text::Xslate' => '< 1.0011', '&apos; bug.'],
    ['Text::Xslate' => '< 1.5021', 'segv in "render" recursion call'],
    ['Text::Xslate' => '< 1.6001', 'possibly memory leaks on VM stack frames. see https://github.com/xslate/p5-Text-Xslate/issues/71'],
    ['Text::Xslate' => '< 2.0005', 'Nested WRAPPER broken https://github.com/xslate/p5-Text-Xslate/issues/79'],
    ['Furl' => '< 0.39', 'unexpected eof in reading chunked body. It makes busy loop.'],
    ['AnyEvent::MPRPC' => '< 0.15', 'switch to Data::MessagePack::Stream'],
    ['Data::MessagePack' => '< 0.46', 'fixed unpacking issue on big-endian system.'],
    ['Data::MessagePack' => '< 0.39', 'packing float numbers fails on some cases'],
    ['FCGI::Client' => '< 0.06', 'fixed large packet issue'],
    ['Starlet' => '< 0.12', 'fix infinite loop when connection is closed while receiving response content'],
    ['Starman' => '< 0.2014', '$res->[1] is broken after output (This is actualized with Plack::Middleware::AccessLog::Timed) https://github.com/miyagawa/Starman/pull/31'],
    ['Starman' => '< 0.1006', 'Fixed 100% CPU loop when an unexpected EOF happens'],
    ['Twiggy' => '< 0.1000', 'busy loop'],
    ['Teng', '< 0.14', 'fixed deflate bug.'],
    ['DBIx::Skinny', '< 0.0742', 'txn_scope bug fixed'],
    ['DBIx::TransactionManager', '< 1.11', 'not execute begin_work at AutoCommit=0.'],
    ['HTTP::MobileAgent' => '< 0.36', 'new x-up-devcap-multimedia(StandAloneGPS) support'],
    ['HTTP::MobileAgent' => '< 0.35', 'Updated $HTMLVerMap and $GPSModelsRe in DoCoMo.pm'],
    ['Encode::JP::Mobile' => '< 0.25', 'resolved FULLWIDTH TILDE issue, etc.'],
    ['Template' => '< 2.15', 'uri filter does not works properly https://rt.cpan.org/Public/Bug/Display.html?id=19593'],
    ['HTML::FillInForm::Lite' => '< 1.11', 'HTML5 style tags support'],
    ['Proc::Daemon' => '< 0.12', 'Init() did not close all filehandles reliably in some cases.'],
    ['ExclusiveLock::Guard' => '< 0.04', 'change of the file stat timing (measures under high load)'],
    ['autobox', '< 2.78', 'segv in END block https://rt.cpan.org/Ticket/Display.html?id=80400'],

    # Broken in specific versions
    ['Amon2::DBI' => '== 0.31', 'transaction management bug'],
    ['Math::Random::MT' => '== 1.15', 'rand() took no notice of argument RT #78200'],
    ['Module::Install' => '== 1.04', 'Broken, http://weblog.bulknews.net/post/33907905561/do-not-ship-modules-with-module-install-1-04'],
    ['Mouse' => '== 1.04', 'Broken, http://d.hatena.ne.jp/gfx/20130208/1360283357'],
    ['Plack::Middleware::AxsLog' => '== 0.20', 'Missing \n'],
);

our @XS = (
    ['JSON' => 'JSON::XS'],
    # ['PPI' => 'PPI::XS'], # I think PPI::XS is outdated.
    ['Plack' => 'HTTP::Parser::XS'],
);
if ($^O eq 'linux') {
    push @XS, ['Filesys::Notify::Simple', 'Linux::Inotify2'];
}

our @FEATURE = (
    ['Amon2' => '< 3.29', 'JSON hijacking detection.'],
    ['Log::Minimal' => '< 0.10', 'LM_COLOR'],
    ['Log::Minimal' => '< 0.08', 'colourful logging'],
    ['Log::Minimal' => '< 0.03', 'ddf'],
    ['Proclet' => '< 0.12', 'Proclet::Declare'],
    ['DBI', '< 1.614' => 'AutoInactiveDestroy'],
    ['Module::Install::XSUtil', '< 0.44' => 'PUREPERL_ONLY=1'],
);

our @OPTIONAL_MODULES = (
    ['LWP', 'LWP::Protocol::https', 'Need to support https'],
);

# ref. Module::Version
sub get_version {
    my $module = shift or croak 'Must get a module name';
    my $metadata = Module::Metadata->new_from_module($module);
    $metadata ? $metadata->version : undef;
}

sub debugf {
    my $self = shift;
    print "# @_\n" if $self->{verbose};
}

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub check {
    my ($self) = @_;
    my $failed = 0;
    $failed += $self->check_security();
    $failed += $self->check_performance();
    $failed += $self->check_bugs();
    $failed += $self->check_xs_installed();
    $failed += $self->check_feature();
    return $failed;
}

sub matches_version {
    my($self, $module, $spec, $version) = @_;

    my $requirements = CPAN::Meta::Requirements->new;
    $requirements->add_string_requirement($module, $spec);

    $requirements->accepts_module($module, $version);
}

sub _check_issue {
    my ($self, $patterns, $type_name) = @_;
    my $failed = 0;
    for my $row (@$patterns) {
        my $ver = get_version($row->[0]);
        if (defined $ver) {
            $self->debugf("$row->[0] $ver");
            if ($self->matches_version($row->[0], $row->[1], $ver)) {
                printf "[$type_name] %s %s %s: %s\n", $row->[0], $ver, $row->[1], $row->[2];
                $failed++;
            }
        } else {
            $self->debugf("$row->[0] is not found");
        }
    }
    return $failed;
}

sub check_security {
    my $self = shift;
    $self->_check_issue(\@SECURITY, 'SECURITY');
}

sub check_performance {
    my $self = shift;
    $self->_check_issue(\@PERFORMANCE, 'PERFORMANCE');
}

sub check_bugs {
    my $self = shift;
    $self->_check_issue(\@BUG, 'BUG');
}

sub check_xs_installed {
    my ($self) = @_;
    my $failed = 0;
    for my $row (@XS) {
        my $pmver = get_version($row->[0]);
        if (defined $pmver) {
            my $xsver = get_version($row->[1]);
            if (defined $xsver) {
                $self->debugf("$row->[1] is also installed");
            } else {
                printf "[XS] %s is need to install for better performance for %s\n", $row->[1], $row->[0];
            }
        } else {
            $self->debugf("$row->[0] is not installed");
        }
    }
}

sub _check_optional {
    my ($self, $rules, $type_name) = @_;
    my $failed = 0;
    for my $row (@$rules) {
        my $pmver = get_version($row->[0]);
        if (defined $pmver) {
            my $xsver = get_version($row->[1]);
            if (defined $xsver) {
                $self->debugf("$row->[1] is also installed");
            } else {
                printf "[$type_name] %s => %s: %s\n", $row->[1], $row->[0], $row->[2];
            }
        } else {
            $self->debugf("$row->[0] is not installed");
        }
    }
}

sub check_feature {
    my $self = shift;
    $self->_check_optional(\@OPTIONAL_MODULES, 'OPTIONAL_MODULES');
}

if (not defined caller(0)) {
    my $checker = __PACKAGE__->new();
    $checker->{verbose}++ if $ENV{DEBUG};
    $checker->check() or print "OK\n";
}

1;

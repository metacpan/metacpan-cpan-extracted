#line 1 "inc/Module/Install/RTx.pm - /usr/local/lib/perl5/site_perl/5.8.2/Module/Install/RTx.pm"
# $File: //member/autrijus/Module-Install-RTx/lib/Module/Install/RTx.pm $ $Author: autrijus $
# $Revision: #8 $ $Change: 9428 $ $DateTime: 2003/12/25 13:19:26 $ vim: expandtab shiftwidth=4

package Module::Install::RTx;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

$Module::Install::RTx::VERSION = '0.03';

use strict;
use FindBin;
use File::Basename;

sub RTx {
    my ($self, $name) = @_;

    $self->name("RTx-$name")
        unless $self->name;
    $self->abstract("RT $name Extension")
        unless $self->abstract;
    $self->version_from (-e "$name.pm" ? "$name.pm" : "lib/RTx/$name.pm")
        unless $self->version;

    my @prefixes = ($ENV{PREFIX}, qw(/opt /usr/local /home /usr /sw ));

    {
        local @INC = (
            @INC,
            $ENV{RTHOME},
            map {( "$_/rt3/lib", "$_/lib/rt3", "$_/lib" )} grep $_, @prefixes
        );
        until ( eval { require RT; $RT::LocalPath } ) {
            warn "Cannot find the location of RT.pm that defines \$RT::LocalPath.\n";
            $_ = prompt("Path to your RT.pm:") or exit;
            push @INC, $_, "$_/rt3/lib", "$_/lib/rt3";
        }
    }

    print "Using RT configurations from $INC{'RT.pm'}:\n";

    $RT::LocalVarPath	||= $RT::VarPath;
    $RT::LocalPoPath	||= $RT::LocalLexiconPath;
    $RT::LocalHtmlPath	||= $RT::MasonComponentRoot;

    my %path;
    my $with_subdirs = $ENV{WITH_SUBDIRS};
    @ARGV = grep { /WITH_SUBDIRS=(.*)/ ? (($with_subdirs = $1), 0) : 1 } @ARGV;
    my %subdirs = map { $_ => 1 } split(/\s*,\s*/, $with_subdirs);

    foreach (qw(bin etc html po sbin var)) {
        next unless -d "$FindBin::Bin/$_";
        next if %subdirs and !$subdirs{$_};
        $self->no_index( directory => $_ );

        no strict 'refs';
        my $varname = "RT::Local" . ucfirst($_) . "Path";
        $path{$_} = ${$varname} || "$RT::LocalPath/$_";
    }

    $path{$_} .= "/$name" for grep $path{$_}, qw(etc po var);
    print "./$_\t=> $path{$_}\n" for sort keys %path;
    my $args = join(', ', map "q($_)", %path);

    $self->postamble(<< ".");
install ::
\t\$(NOECHO) \$(PERL) -MExtUtils::Install -e \"install({$args})\"
.

    if (-e 'etc/initialdata') {
        print "For first-time installation, type 'make initialize-database'.\n";
        my $lib_path = dirname($INC{'RT.pm'});
        $self->postamble(<< ".");
initialize-database ::
\t\$(NOECHO) \$(PERL) -Ilib -I"$lib_path" "$RT::BasePath/sbin/rt-setup-database" --action=insert --datafile=etc/initialdata
.
    }
}

1;

__END__

#line 154

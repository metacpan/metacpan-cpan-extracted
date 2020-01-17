package Object::HashBase::Inline;
use strict;
use warnings;

our $VERSION = '0.009';

BEGIN { $Object::HashBase::Test::NO_RUN = 1 }
use Object::HashBase;
use Object::HashBase::Test;

my $hb_file = $INC{'Object/HashBase.pm'};
my $t_file  = $INC{'Object/HashBase/Test.pm'};

sub inline {
    my ($prefix, $version) = @_;
    $version = $VERSION unless defined $version;

    my $path = $prefix;
    $path =~ s{::}{/}g;
    $path = "lib/$path";
    my $partial = '';

    for my $part (split /\//, "$path") {
        $partial = join '/', grep { $_ } $partial, $part;
        mkdir($partial) unless -d $partial;
    }

    $path .= "/HashBase.pm";

    mkdir('t') unless -d 't';

    open(my $hbf, '>', $path)          or die "Could not create '$path': $!";
    open(my $tf,  '>', 't/HashBase.t') or die "Could not create 't/HashBase.t': $!";

    open(my $hin, '<', $hb_file) or die "Could not open '$hb_file': $!";
    open(my $tin, '<', $t_file)  or die "Could not open '$t_file': $!";


    print $hbf <<"    EOT";
package $prefix\::HashBase;
use strict;
use warnings;

our \$VERSION = '$version';

#################################################################
#                                                               #
#  This is a generated file! Do not modify this file directly!  #
#  Use hashbase_inc.pl script to regenerate this file.          #
#  The script is part of the Object::HashBase distribution.     #
#  Note: You can modify the version number above this comment   #
#  if needed, that is fine.                                     #
#                                                               #
#################################################################

{
    no warnings 'once';
    \$$prefix\::HashBase::HB_VERSION = '$Object::HashBase::VERSION';
    \*$prefix\::HashBase::ATTR_SUBS = \\\%Object::HashBase::ATTR_SUBS;
    \*$prefix\::HashBase::ATTR_LIST = \\\%Object::HashBase::ATTR_LIST;
    \*$prefix\::HashBase::VERSION   = \\\%Object::HashBase::VERSION;
    \*$prefix\::HashBase::CAN_CACHE = \\\%Object::HashBase::CAN_CACHE;
}

    EOT

    print $tf <<"    EOT";
use strict;
use warnings;

use Test::More;

    EOT

    my $writing = 0;
    while (my $line = <$hin>) {
        if ($line =~ m/<-- START -->/) {
            $writing = 1;
            next;
        }

        if ($line =~ m/^=head1 INCLUDING IN YOUR DIST$/) {
            $writing = 0;
            print $hbf <<"            EOT";
=head1 THIS IS A BUNDLED COPY OF HASHBASE

This is a bundled copy of L<Object::HashBase>. This file was generated using
the
C<$0>
script.

            EOT
            next;
        }
        if ($line =~ m/^=head1 /) {
            $writing = 1;
        }

        next unless $writing;

        $line =~ s/\QObject::\E/$prefix\::/g;

        print $hbf $line;
    }

    $writing = 0;
    while (my $line = <$tin>) {
        if ($line =~ m/<-- START -->/) {
            $writing = 1;
            next;
        }

        next unless $writing;

        $line =~ s/\QObject::HashBase::Test::\E/main\::/g;
        $line =~ s/\QObject::\E/$prefix\::/g;
        print $tf $line;
    }

    close($hbf);
    close($tf);
}

1;

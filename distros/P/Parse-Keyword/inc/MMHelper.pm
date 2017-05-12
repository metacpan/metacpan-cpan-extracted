package inc::MMHelper;
use strict;
use warnings;

sub makefile_pl_extra {
    return <<'EXTRA';
use File::Spec::Functions 'abs2rel';
use Devel::CallParser 'callparser1_h', 'callparser_linkable';
open my $fh, '>', 'callparser1.h' or die "Couldn't write to callparser1.h";
$fh->print(callparser1_h);
my @linkable = map { abs2rel($_) } callparser_linkable;
unshift @linkable, '$(BASEEXT)$(OBJ_EXT)' if @linkable;
$WriteMakefileArgs{OBJECT} = join(' ', @linkable) if @linkable;
EXTRA
}

sub mm_args {
    return {
        NORECURS => 1,
        clean    => {
            FILES => "callparser1.h",
        }
    };
}

1;

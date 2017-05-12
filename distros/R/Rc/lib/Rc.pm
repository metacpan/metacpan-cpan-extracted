use strict;
package Rc;
use IO::Handle;
use base ('Exporter','DynaLoader');
use vars qw($VERSION @EXPORT_OK $OutputFH);
$VERSION = '0.03';
@EXPORT_OK = qw(walk set_output
	       $OutputFH);
$OutputFH = \*STDOUT;

__PACKAGE__->bootstrap($VERSION);

sub walk {
    local $SIG{__WARN__} = sub {
	if ($_[0] =~ m/^Deep recursion/) {
	    #ignore
	} else {
	    warn $_[0]
	}
    };
    &_walk;
}

sub set_output {
    $OutputFH = shift;
}

no strict 'refs';
for(qw(Undef WordX Cmd RedirX Pipe)) {
    my $c = 'Rc::'.$_.'::ISA';
    @{"$c"} = 'Rc::Node';
}

for (qw(UnaryCmd BinCmd Forin)) {
    my $c = 'Rc::'.$_.'::ISA';
    @{"$c"} = 'Rc::Cmd';
}

# WordX
@Rc::Word::ISA = 'Rc::WordX';
@Rc::Qword::ISA = 'Rc::WordX';

# Cmd <= UnaryCmd
for (qw(Bang Nowait Count Flat Rmfn Subshell Var Case)) {
    my $c = 'Rc::'.$_.'::ISA';
    @{"$c"} = 'Rc::UnaryCmd';
}

# Cmd <= BinCmd
for (qw(Andalso Assign Backq Body Brace Concat Else Epilog
	If Newfn Cbody Orelse Pre Args Switch Match Varsub While Lappend)) {
    my $c = 'Rc::'.$_.'::ISA';
    @{"$c"} = 'Rc::BinCmd';
}

# Node <= RedirX
for (qw(Dup Redir Nmpipe)) {
    my $c = 'Rc::'.$_.'::ISA';
    @{"$c"} = 'Rc::RedirX';
}

package Rc::Undef;
sub type { 'undef' }

package Rc::Nmpipe;

*fd = \&Rc::Redir::fd;
*to = \&Rc::Redir::to;

1;
__END__

=head1 NAME

Rc - parser and backends for 'rc' shell

=head1 SYNOPSIS

If you need a synposis, you should start with an easier project.

=head1 DESCRIPTION

The design of this module is similar to the design of L<B>, the perl
compiler backend.

=head1 WHY RC?

'rc' has a cleaner syntax in comparison to sh or csh.  If your going
to go through the unpleasantness of learning to program in a shell, it
might as well be 'rc'.

=head1 SUPPORT

Send any questions or comments to envy@listbox.com!

If you'd like to subscribe to this mailing list send email to
majordomo@listbox.com.  Thanks!

=head1 AUTHOR

Copyright © 1998 Joshua Nathaniel Pritikin.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

Portions of this sortware include source code from the 'rc' shell.
These portions are Copyright © 1991 Byron Rakitzis.  'rc' is free,
open-source package and is available at most ftp sites that distribute
GNU software.

=cut

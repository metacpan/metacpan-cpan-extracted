
=pod

=head1 NAME

Pod::Stripper - strip all pod, and output what's left

=head1 SYNOPSIS

    $>perl Stripper.pm

or

    #!/usr/bin/perl -w

    use strict;
    use Pod::Stripper;

    my $Stripper = new Pod::Stripper();

    $Stripper->parse_from_filehandle(\*STDIN) unless (@ARGV);

    for my $ARGV (@ARGV) {
        $Stripper->parse_from_file($ARGV);
    }

=head1 DESCRIPTION

This be C<Pod::Stripper>, a subclass of C<Pod::Parser>.  It parses perl files,
stripping out the pod, and dumping the rest (presumably code) to wherever
you point it to (like you do with C<Pod::Parser>).

You could probably subclass it, but I don't see why.

=head2 MOTIVATION

I basically re-wrote C<Pod::Stripper> on two separate occasions, and I know
at least 2 other people who'd use it, and thought It'd make a nice addition.

C<perl -MPod::Stripper -e"Pod::Stripper-E<gt>new()-E<gt>parse_from_file(shift)">
C<  Stripper.pm>

=head2 EXPORTS

None.
This one be object oriented (at least I'm under the impression that it is).

=head2 SEE ALSO

C<Pod::Parser> and L<Pod::Parser>, esp. the C<input_*> and C<output_*> methods

=head1 CAVEAT

This module will correctly strip out get rid of hidden pod,
and preserve hiddencode, but like all pod parsers except C<perl>,
it will be fooled by pod in heredocs (or things like that).

see L<perlpod> and read F<Stripper.pm> for more information.

=head1 AUTHOR

D.H. aka crazyinsomniac|at|yahoo.com.

=head1 LICENSE

Copyright (c) 2002 by D.H. aka crazyinsomniac|at|yahoo.com.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 PROPS

props to all the perlmonks at perlmonks.org, and especiall danger
and the ones who showed interest in Pod::Stripper

http://perlmonks.org/index.pl?node=Pod::Stripper

=cut


package Pod::Stripper; # this one is a little more stylish (see perlstyle)
use strict;
use Pod::Parser;
local $^W = 1; # flip on teh warnings

use vars qw/ @ISA $VERSION/;

$VERSION = 0.22;

@ISA = qw(Pod::Parser); # Pod'Parser is also legal

sub begin_input {
    my ($Stripper) = @_;

## SUPER cause I override parseopts, so the user can't mess w/it
    $Stripper->SUPER::parseopts('-want_nonPODs'    => 1,
                                '-process_cut_cmd' => 9,

                              ,);

    $Stripper->{__2hidden_code}=0;
    return undef;
}

sub cutting {
   my ($Stripper, $cutting) = @_;

   $Stripper->{_CUTTING} = $cutting  if defined $cutting;

   return $$Stripper{_CUTTING};
}

sub begin_pod {
    my ($Stripper) = @_;

    $Stripper->cutting(1);

    return undef;
}

sub end_pod {
    my ($Stripper) = @_;

    $Stripper->cutting(0);

    return;
}

sub preprocess_paragraph
{
    my ($Stripper, $text) = @_;

    if( $Stripper->cutting() ) {
        my $out_fh = $Stripper->output_handle();
        print $out_fh $text;
        return undef;
    }
    else {
        return $text;
    }
}

sub command
{
    my ($Stripper, $command, $paragraph, $line_num, $pod_para) = @_;

    if($paragraph =~ m/^=cut/mg) {
        $Stripper->{__2hidden_code} = 1 ;
        ## it's hidden code (the unseen =cut command)
    }


    if ($command eq 'cut') {
        $Stripper->cutting(1);
        ## it's non-pod now
    }
    else {
        $Stripper->cutting(0);
        ## it's pod now
    }
}

sub verbatim { &textblock(@_); } ## cause hidden code can be either

sub textblock {
    my ($Stripper, $paragraph, $line_num, $pod_para) = @_;

## guess what we got? that's right, hidden code
    if($Stripper->{__2hidden_code}) {
        $Stripper->{__2hidden_code} = 0;
        my $out_fh = $Stripper->output_handle();
        print $out_fh $paragraph;
    }

}
    

sub parseopts {undef}

1;
################################################################################
################################################################################

=head1 The Following is more interesting if you read Stripper.pm raw

=cut

package main;

unless(caller()) {
    my $Stripper = new Pod::Stripper();
    
    seek DATA,0,0;
    
    $Stripper->parse_from_filehandle(\*DATA);

=head1 TEST CASE FOLLOWS - NOT POD NOR CODE

==head2 HEY THIS POD TOO (REALLy, == is valid, although some parsers might disagree)

podchecker will not complain

=head2 ABTEST
print "THIS IS HIDDEN POD";
=cut

print ">>>>>>>>>>>>>>> I AM NOT HIDDEN POD.  PERL WILL EXECUTE ME";

=head2 CUT

had to make sure

=cut

my $BUT_BEFORE_THE_MODULE_ENDS = <<'A_TEST';

=head2 I AM INSIDE A HEREDOC

WHERE ARE YOU?

=cut

=head2 I AM HIDDEN POD INSIDE A HEREDOC
warn "really, I am"
=cut

print "AND I AM HIDDEN CODE INSIDE A HEREDOC";

=head2 BOO

but hey, if the pod inside a heredoc gets eaten by a pod parser (as it shoulD)
I see no problem here

=cut

A_TEST

}

1; ### end of modules

__END__

=head2 WELL IF THIS WASN'T AFTER C<__END__>
"this would still be hidden pod";
=cut

print "AND THIS WOULD STILL BE HIDDEN CODE";

=head2 THIS REALLY IS AN UGLY HACK

yes, it is

=cut

use Modern::Perl;
use HTML::TreeBuilder::XPath;
use WWW::Mechanize;
use Readonly;

Readonly::Scalar my $DATE_XPATH    => q<//div[@id='main_page']//div[@class='rbcontent']/div[2]>;
Readonly::Scalar my $CONTENT_XPATH => q<//div[@id='main_page']//div[@class='problem_content']>;
Readonly::Scalar my $LINK => 'http://projecteuler.net/index.php?section=problems&id=%d';
Readonly::Scalar my $BASE_CODE => << '__END_CODE';
package Project::Euler::Problem::P%03d;

use Carp;
use Modern::Perl;
use Moose;

with 'Project::Euler::Problem::Base';
use Project::Euler::Lib::Types  qw/ /;  ### TEMPLATE ###


=head1 NAME

Project::Euler::Problem::P%03d - Solutions for problem %03d

=head1 VERSION

Version v0.1.0

=cut

use version 0.77; our $VERSION = qv("v0.1.0");

=head1 SYNOPSIS

L<< http://projecteuler.net/index.php?section=problems&id=%d >>

    use Project::Euler::Problem::P%03d;
    my $p%d = Project::Euler::Problem::P%03d->new;

    my $default_answer = $p%d->solve;

=head1 DESCRIPTION

This module is used to solve problem #%03d

### TEMPLATE ###

=head1 Problem Attributes

### TEMPLATE ###

=cut


=head1 SETUP

=head2 Problem Number

    %03d

=cut

sub _build_problem_number {
    ### TEMPLATE ###
}


=head2 Problem Name

    ### TEMPLATE ###

=cut

sub _build_problem_name {
    ### TEMPLATE ###
}


=head2 Problem Date

    %s

=cut

sub _build_problem_date {
    return q{%s};
}


=head2 Problem Desc

%s

=cut

sub _build_problem_desc {
    return <<'__END_DESC';

%s

__END_DESC
}


=head2 Default Input

### TEMPLATE ###

=cut

sub _build_default_input {
    ### TEMPLATE ###
}


=head2 Default Answer

%s

=cut

sub _build_default_answer {
    %s
}


=head2 Has Input?

### TEMPLATE ###

=cut
### TEMPLATE ###
#has '+has_input' => (default => 0);


=head2 Help Message

### TEMPLATE ###

=cut

sub _build_help_message {

    return <<'__END_HELP';

### TEMPLATE ###

__END_HELP

}



=head1 INTERNAL FUNCTIONS

=head2 Validate Input

### TEMPLATE ###

=cut

sub _check_input {
### TEMPLATE ###
}



=head2 Solving the problem

### TEMPLATE ###

=cut

sub _solve_problem {
    my ($self, $input) = @_;

    ### TEMPLATE ###
}


=head1 AUTHOR

Adam Lesperance, C<< <lespea at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-project-euler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Project-Euler>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Project::Euler::Problem::P%03d


=head1 ACKNOWLEDGEMENTS



=head1 COPYRIGHT & LICENSE

Copyright 2009 Adam Lesperance.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


#  Cleanup the Moose stuff
no Moose;
__PACKAGE__->meta->make_immutable;
1; # End of Project::Euler::Problem::P%03d
__END_CODE



my ($num, $answer) = @ARGV;
$answer //= '### TEMPLATE ###';

die  unless  defined $num;
my $url = sprintf($LINK, $num);
my $mech = WWW::Mechanize->new;
my $resp = $mech->get($url);
my $tree = HTML::TreeBuilder::XPath->new_from_content($resp->as_string);
$tree->elementify;

my $date = $tree->findvalue($DATE_XPATH);
my $desc = $tree->findvalue($CONTENT_XPATH);
$tree->delete;

die "no date\n" unless  defined $date;
die "no desc\n" unless  defined $desc;


printf( $BASE_CODE,
        ($num) x 10,
        ($date) x 2,
        ($desc) x 2,
        $answer,
        "return $answer;",
        ($num) x 2
);

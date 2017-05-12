package Net::StackExchange2;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Net::StackExchange2::V2;

our $VERSION = "0.05";

sub new {
	my $class = shift;#unused here
	my $params = shift;
	return Net::StackExchange2::V2->new($params);
}

1; # End of Net::StackExchange2
__END__

=head1 NAME

Net::StackExchange2 - Perl interface to the new StackExchange 2.1 API

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS
    
See DESIGN NOTES below about how the API is designed. See stackexchange api docs for more on the API. Below are some example usages.

    use Net::StackExchange2;
    #For read-only methods.
    my $se = Net::StackExchange2->new({site => 'stackoverflow'});
    
    #OR
    
    #for methods that require auth.
    my $se = Net::StackExchange2->new(
        {site=>"stackoverflow", access_token => '<THE ACCESS TOKEN>' , key => '<YOUR APP KEY>'}
    );
    
    #A few examples:
    
    #Every entity will have an xxx_all() that gets all records,
    #and another xxx() that takes ONE id or a number of ids
    
    my $ret =  $se->answers->answers_all({ order=> "desc", sort=>"votes" });
    my $ret = $se->answers->answers(14586834);#pass one single ID
    my $ret = $se->answers->answers([4449779, 4477003]);#or pass many in an array ref
    
    my $ret  = $se->search->search({tagged=>"perl"});
    
    my $ret = $se->tags->tags_top_askers("perl", "month");
    
    #filters are also supported. 

    #This method gets comments from one user to another and only retrives the body of the comment
    my $ret = $se->users->users_comments_toid(368070,22656, {filter => '!mRNaB_KjjP'});




=head1 DESCRIPTION

This module is a perl wrapper to the stack exchange api. It mostly has a one to one mapping with the api 
methods documented here : L<http://api.stackexchange.com/docs>. Also see L<Net::StackExchange2::V2>. 

=head1 DESIGN NOTES

I designed the methods on this module to be flexible and intuitive. The stackexchange api methods are themselves pretty intuitive and follow
a pattern. I'm also a perl beginner and purposely chose not to use Moose or Moo so that I could design the OO myself as a learning exercise.

Please file issues on the github repository if you feel there is anything wrong with the design.

Each entity in the api (Questions, Answers, Badges, Tags) usually has a url/method to get all and another one that takes a vector of ids, for tags the 
ids are the tag names. This module has a similar pattern of methods over all entities. 

Examples:
    
    my $se = Net::StackExchange2->new({site => 'stackoverflow'});

    #The 'all' methods... --------------------------------------------------------
    $se->answers->answers_all();
    $se->badges->badges_all();
    $se->tags->tags_all();
    $se->posts->posts_all();
    #get the picture :) ?

    #Methods that take an id -----------------------------------------------------
    $se->answers->answers(1478554);#get ONE answer 
    
    #must be passed in ARRAYREF
    $se->answers->answers([1478554,1478555]);#get two answers

    #get info for the tags perl, unix, c# and javascript
    my $ret = $a->tags->tags_info(["perl", "unix", "c%23", "javascript"]);

    $se->badges->badges(5);#get ONE badge
    $se->badges->badges([5,10,15]);#get three badges. Note ARRAYREF

    #methods with extra params  ----------------------------------------------------
    
    #sorts gold first, then silver then bronze.
    my $ret = $a->badges->badges([5, 10, 15], {sort => 'rank', order => 'asc'});
    #get a particular question with a filter that fetches only body content 
    my $ret = $a->questions->questions(14669096, { filter => '!f.Ac2qi(R1tVt'});
    
    
    #one-to-one mapping with api urls -----------------------------------------------
    
    #if you check out the API docs you'll see badges has the following url methods:
    
    /badges                  => $se->badges->badges_all();
    /badges/{ids}            => $se->badges->badges(5); 
                             OR $se->badges->badges([5,10,15]); 
                             OR $se->badges->badges([11,12,13,14,15], {sort => 'rank', order => 'asc'}); 
    badges/name              => $se->badges->badges_name();
    badges/{ids}/recipients  => $se->badges->badges_recipients([10,15], { filter => 'some_filter'});
    badges/tags              => $se->badges->badges_tags();

    #NOTE: All dates are send and received in Unix epoch time. See http://en.wikipedia.org/wiki/Unix_time

=head1 AUTHOR

Gideon Israel Dsouza, C<< <gideon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-stackexchange2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-StackExchange2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::StackExchange2

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-StackExchange2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-StackExchange2>

=item * CPAN Ratings

Please give the module a nice rating if you think it was helpful :) L<http://cpanratings.perl.org/d/Net-StackExchange2>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-StackExchange2/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Gideon Israel Dsouza.

This library is distributed under the freebsd license:

L<http://opensource.org/licenses/BSD-3-Clause> 
See FreeBsd in TLDR : L<http://www.tldrlegal.com/license/bsd-3-clause-license-(revised)>

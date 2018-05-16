package TaskPipe::Template_Task_ScrapeStub;

use Moose;
extends 'TaskPipe::Template_Task';

has name => (is => 'ro', isa => 'Str', default => 'Scrape_Stub');
has template => (is => 'ro', isa => 'Str', default =>

q|# This is a file stub for a typical scraping task. To customise
#
# - fill out the subs you need
# - remove the ones you dont
# - strip comments (or replace with your own?)
# - in your text editor choose 'save as' and ***choose a suitable
#   filename *** (do NOT call your task 'Scrape_Stub' !)


package <% task_module_prefix %>::<% task_identifier %><% name %>;

use Moose;
extends 'TaskPipe::Task';


# if you are going to use Web::Scraper (see the 'ws' attribute below)
# then you need to 'use' the module:

use Web::Scraper; 



# provide some test data so you can 'unit test' your task:

has test_pinterp => (is => 'ro', isa => 'ArrayRef[HashRef]', default => sub{[
    {
        # test sets should have url and Referer defined:
        # for example:
        url => 'https://www.example.com/test-url-1',
        headers => {
            Referer => 'https://www.example.com/test-referer-1'
        }
    },

    {
        # more test data...
    }
]});




# You can provide a Web::Scraper in the 'ws' attribute:

has ws => (is => 'ro', isa => 'Web::Scraper', default => sub {
    scraper {
        #process => 'a.something', 'myvar' => 'TEXT';
        # ... fill in scraper block
    }
});




# Post process the results from ws if they need further formatting.
# (if not, just omit the 'post_process' method)

sub post_process{
    my ($self,$results) = @_;

    # $results contains whatever ws returned.
    # Make sure to output an arrayref of hashrefs.
    # If no post processing is required you can remove this sub.

    return $results;  # arrayref of hashrefs after modification
}





# If you do not want to use Web::Scraper, you can remove the 'ws' 
# attribute, and the 'post_process' subroutine above, and instead
# override the 'scrape' method. In this case, uncomment the lines
# below and fill in the detail
#
# sub scrape{
#     my ($self) = @_;
#
#     # fill in code here which extracts a list of results
#     # as an arrayref of hashrefs from the retrieved web page
#     # you can use $self->page_content to get the page text
#     # and the url is available in $self->url
#
#     return $results; # an arrayref of hashrefs
# }






# If you are using a rendering UserAgentHandler (e.g. PhantomJS)
# and you want to make sure the page has loaded before grabbing the 
# content, then you can include a 'poll_for' attribute, which
# contains a list of css selectors of elements to wait for.
# This is most important when dealing with webpages which load content
# via ajax, as e.g. PhantomJS doesn't consider ajax when deciding
# if the page has loaded

has poll_for => (is => 'rw', isa => 'ArrayRef[Str]', default => sub{[
    'div.wait-for-me',
    # ...
]});






# 'retry_condition' and 'fail_condition' subs are optional
# these subs control what to do when unexpected results are
# returned

sub retry_condition {
    my ($self,$results) = @_;

    # If $results don't look right, maybe the scrape failed
    # without returning an error code (ie normally a partially 
    # loaded page, timeout halfway through the response etc.)
    # So we want to try the scrape again.
    #
    # In this sub, decide which condition(s) should result in 
    # a retry. If you omit this sub, the default will
    # attempt the retry if $results is undef or an empty list
    #
    # Return 
    #  0 = no need for a retry
    #  1 = something wrong, retry
    #
    # For example, we could check there is at least one result
    # which has 'expected_important_param' defined:

    my $condition =
        ( $results->[0] && $results->[0]->{expected_important_param} ) ?
            1: 0;

    return $condition;
}





sub fail_condition{
    my ($self,$results) = @_;

    # what kind of results should lead us to report an error?
    # This is not the same as 'retry_condition', for the 
    # following reasons:
    #
    # 1. fail_condition will only be checked *after* retry 
    # has repeatedly failed
    #
    # 2. if retry failed it may not mean an error, just
    # that information is not available. This depends on
    # your scrape. e.g. if you always expect data, then 
    # you should fail if there is none. But if some pages
    # just don't have data, then you may not want to fail
    # at all. Some suggestions:

    return 0;   # retry according to retry_condition, but 
                # never report an error. Just move on to
                # the next record
                
    # alternatively:

    my $condition = $self->retry_condition( $results );
    return $condition;  # retry according to retry_condition
                        # if retries not successful, fail 
                        # on the same condition

    # or something like

    my $condition = defined $results? 0: 1;
    return $condition;  # retry according to retry_condition
                        # but fail only if $results is 
                        # undefined

}

__PACKAGE__->meta->make_immutable;
1;|

);

=head1 NAME

TaskPipe::Template_Task_ScrapeStub - template for the Scrape_Stub task

=head1 DESCRIPTION

This is the template for the Scrape_Stub task which is deployed by default when C<taskpipe deploy files> is run.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


1;




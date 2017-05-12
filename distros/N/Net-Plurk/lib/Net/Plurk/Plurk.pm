package Net::Plurk::Plurk;
use Moose;
use Moose::Util::TypeConstraints;
use DateTime::Format::Strptime;

=head1 NAME

Net::Plurk::Plurk 

=head1 SYNOPSIS

Single Plurk data

    plurk_id: The unique Plurk id, used for identification of the plurk. 
    qualifier: The English qualifier, can be "says", show all:
        qw/ loves likes shares gives hates wants has will asks wishes was /
        qw/ feels thinks says is : freestyle hopes needs wonders /
    qualifier_translated: Only set if the language is not English,
        will be the translated qualifier. Can be "siger" if plurk.lang is "da" (Danish). 
    is_unread: Specifies if the plurk is read, unread or muted. Show example data
        is_unread=0 //Read
        is_unread=1 //Unread
        is_unread=2 //Muted
    plurk_type:
        plurk_type=0 //Public plurk
        plurk_type=1 //Private plurk
        plurk_type=2 //Public plurk (responded by the logged in user)
        plurk_type=3 //Private plurk (responded by the logged in user)
    user_id: Which timeline does this Plurk belong to. 
    owner_id: Who is the owner/poster of this plurk. 
    posted: The date this plurk was posted. 
    no_comments:
        If set to 1, then responses are disabled for this plurk.
        If set to 2, then only friends can respond to this plurk. 
    content: The formatted content, emoticons and images will be turned into IMG tags etc. 
    content_raw: The raw content as user entered it
    response_count: How many responses does the plurk have. 
    responses_seen: How many of the responses have the user read.
    limited_to: If the Plurk is public limited_to is null.
        If the Plurk is posted to a user's friends then limited_to is [0].
        If limited_to is [1,2,6,3] then it's posted only to these user ids. V
=cut

my $Strp = new DateTime::Format::Strptime(
# Fri, 05 Jun 2009 23:07:13 GMT
# %a,  %d %b  %Y   %T       %Z
    pattern => '%a, %d %b %Y %T %Z',
);

subtype 'Net::Plurk::Value::DateTime' => as class_type('DateTime');
coerce 'Net::Plurk::Value::DateTime'
    => from 'DateTime'
        => via { DateTime->new( $_ ) }
    => from 'Str'
        => via { $Strp->parse_datetime($_) };

has 'plurk_id' => (is => 'ro', isa => 'Int');
has 'qualifier' => (is => 'ro', isa => enum([qw
        [ loves likes shares gives hates wants has will asks wishes was feels thinks says is : freestyle hopes needs wonders ]
        ]));
has 'qualifier' => (is => 'ro', isa => 'Str');
has 'lang' => (is => 'ro', isa => 'Str');
has 'is_unread' => (is => 'ro', isa => 'Int');
has 'plurk_type' => (is => 'ro', isa => 'Int');
has 'user_id' => (is => 'ro', isa => 'Str');
has 'owner_id' => (is => 'ro', isa => 'Str');
has 'posted' => (is => 'rw', isa => 'Net::Plurk::Value::DateTime', coerce => 1);
has 'no_comments' => (is => 'ro', isa => 'Int');
has 'content' => (is => 'ro', isa => 'Str');
has 'content_raw' => (is => 'ro', isa => 'Str');
has 'response_count' => (is => 'ro', isa => 'Int');
has 'responses_seen' => (is => 'ro', isa => 'Int');
has 'limited_to' => (is => 'ro', isa => 'ArrayRef[Int] | Undef');

no Moose::Util::TypeConstraints;
no Moose;
__PACKAGE__->meta->make_immutable;
1;

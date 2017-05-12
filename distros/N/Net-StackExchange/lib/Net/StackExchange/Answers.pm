package Net::StackExchange::Answers;
BEGIN {
  $Net::StackExchange::Answers::VERSION = '0.102740';
}

# ABSTRACT: Provides accessors for an answer

use Moose;

has [
    qw{
        answer_id
        question_id
        creation_date
        up_vote_count
        down_vote_count
        view_count score
      }
    ] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'accepted' => (
    is       => 'ro',
    isa      => 'Boolean',
    required => 1,
    coerce   => 1,
);

has [
    qw{
        answer_comments_url
        title
      }
    ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has [
    qw{
        locked_date
        last_edit_date
        last_activity_date
      }
    ] => (
    is  => 'ro',
    isa => 'Int',
);

has 'owner' => (
    is  => 'ro',
    isa => 'Net::StackExchange::Owner',
);

has 'community_owned' => (
    is       => 'ro',
    isa      => 'Boolean',
    required => 1,
    coerce   => 1,
);

has 'body' => (
    is  => 'ro',
    isa => 'Str',
);

has 'comments' => (
    is  => 'ro',
    isa => 'ArrayRef[Net::StackExchange::Comments]',
);

has '_NSE' => (
    is       => 'ro',
    isa      => 'Net::StackExchange',
    required => 1,
);

__PACKAGE__->meta()->make_immutable();

no Moose;

1;



=pod

=head1 NAME

Net::StackExchange::Answers - Provides accessors for an answer

=head1 VERSION

version 0.102740

=head1 SYNOPSIS

    use Net::StackExchange;

    my $se = Net::StackExchange->new( {
        'network' => 'stackoverflow.com',
        'version' => '1.0',
    } );

    my $answers_route   = $se->route('answers');
    my $answers_request = $answers_route->prepare_request( { 'id' => '1036353' } );

    $answers_request->body(1);

    my $answers_response = $answers_request ->execute( );
    my $answer           = $answers_response->answers(0);

    print "__Answer__\n";
    print "Title: ", $answer->title(), "\n";
    print "Body: ",  $answer->body (), "\n";

=head1 ATTRIBUTES

=head2 C<answer_id>

Returns id of the answer.

=head2 C<accepted>

Returns whether this answer is the accepted answer on its question.

=head2 C<answer_comments_url>

Returns a link to the method that returns comments on this answer.

=head2 C<question_id>

Returns id of the question this post is or is on.

=head2 C<locked_date>

Returns date this question was locked.

=head2 C<owner>

Returns a L<Net::StackExchange::Owner> object.

=head2 C<creation_date>

Returns date this post was created.

=head2 C<last_edit_date>

Returns last time this post was edited.

=head2 C<last_activity_date>

Returns last time this post had any activity.

=head2 C<up_vote_count>

Returns number of up votes on this post.

=head2 C<down_vote_count>

Returns number of down votes on this post.

=head2 C<view_count>

Returns number of times this post has been viewed.

=head2 C<score>

Returns score of this post.

=head2 C<community_owned>

Returns whether this post is community owned.

=head2 C<title>

Returns title of this post, in plaintext.

=head2 C<body>

Returns body of this post, rendered as HTML.

=head2 C<comments>

Returns a L<Net::StackExchange::Comments> object.

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


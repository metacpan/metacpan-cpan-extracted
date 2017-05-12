package Net::Twitter::RandomUpdate;

use strict;
use warnings;

use Net::Twitter;

our $VERSION = join( '.', 1, map{ $_ - 53 } ( '$Rev: 59 $' =~ /(\d+)/g ) ); 

my $quotes = [
    'How to store your baby walker: First, remove baby.',
    'I get to go to lots of overseas places, like Canada.',
    'The team has come along slow but fast.',
    'Most cars on our roads have only one occupant, usually the driver.',
    'Football players win football games.',
    'Most lies about blondes are false.',
    'I love California, I practically grew up in Phoenix.',
    'Strangely, in slow motion replay, the ball seemed to hang in the air for even longer.',
    'We\'re just physically not physical enough.',
    'The world is more like it is now then it ever has before.',
    'I cannot tell you how grateful I am -- I am filled with humidity.',
    'I have a God-given talent. I got it from my dad.',
    'Traditionally, most of Australia\'s imports come from overseas.',
];

sub new {
    my ( $class, $notes ) = @_;

    return bless( $notes || $quotes, $class );
}

{
    my $user;
    sub username {
        return $user = pop;
    }

    my $pass;
    sub password {
        return $pass = pop;
    }

    my $reg = .05; 
    sub regularity {
        return $reg = pop;
    }

    sub tweet {
        return if ( rand() > $reg );
        my ($self) = @_;

        my $tweet = Net::Twitter->new(
            'username' => $user,
            'password' => $pass,
            'source'   => 'randomupdate',
        );

        my @tweets = @$self;
        $tweet->update( $tweets[ int( rand( @tweets ) ) ] ); 

        return;
    }
}

1;

__END__

=head1 NAME

Net::Twitter::RandomUpdate - Make people think you're paying attention to Twitter 

=head1 DESCRIPTION

Will submit a random tweet at generally random times with some canned quotes or 
quotes defined by the implementor.

=head1 METHODS

=head2 new( [ optional_quotes ] );

Will return a new object. You can pass an OPTIONAL reference to an array with
a list of tweets the module will choose from.  If ignored, the following will
be used:

    my $quotes = [
        'How to store your baby walker: First, remove baby.',
        'I get to go to lots of overseas places, like Canada.',
        'The team has come along slow but fast.',
        'Most cars on our roads have only one occupant, usually the driver.',
        'Football players win football games.',
        'Most lies about blondes are false.',
        'I love California, I practically grew up in Phoenix.',
        'Strangely, in slow motion replay, the ball seemed to hang in the air for even longer.',
        'We\'re just physically not physical enough.',
        'The world is more like it is now then it ever has before.',
        'I cannot tell you how grateful I am -- I am filled with humidity.',
        'I have a God-given talent. I got it from my dad.',
        'Traditionally, most of Australia\'s imports come from overseas.',
    ];

=head2 tweet

Will send a tweet to the specified account if it falls within the random
regularity selection.

=head1 ATTRIBUTES

=head2 regularity 

Default: .05 (will only tweet 5% of the time)

An integer <= 1 and >= 0, indicating the percentage of times you want
the module to tweet.  Good for use in a crontab, for example.

=head2 username

The username of the account.

=head2 password

The password of the account.

=head1 EXAMPLES

    use Net::Twitter::RandomUpdate;

    # Use the default tweet-set send a tweet 100% of the time
    my $rand = Net::Twitter::RandomUpdate->new();
    $rand->regularity(1);
    $rand->password('pass');
    $rand->username('user');
    $rand->tweet();

    # Use self-defined tweet-set, send a tweet 50% of the time 
    my $rand = Net::Twitter::RandomUpdate->new( [ qw( hi ) ] );
    $rand->regularity(.5);
    $rand->password('pass');
    $rand->username('user');
    $rand->tweet();

=head1 SEE ALSO

=over

=item L<Net::Twitter>

=back

=head1 AUTHOR

Trevor Hall, E<lt>wazzuteke@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Trevor Hall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


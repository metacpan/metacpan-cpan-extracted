package TAP::Stream;
$TAP::Stream::VERSION = '0.44';
# ABSTRACT: Combine multiple TAP streams with subtests

use Moose;
use TAP::Stream::Text;
use namespace::autoclean;
with qw(TAP::Stream::Role::ToString);

has '_stream' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[TAP::Stream::Role::ToString]',
    default => sub { [] },
    handles => {
        add_to_stream => 'push',
        is_empty      => 'is_empty',
    },
);

sub to_string {
    my $self = shift;
    return '' if $self->is_empty;

    my $to_string = '';

    my $test_number = 0;

    foreach my $next ( @{ $self->_stream } ) {
        $test_number++;
        chomp( my $tap = $next->to_string );
        my $name = $next->name;
        $to_string .= $self->_build_tap( $tap, $name, $test_number );
    }
    $to_string .= "1..$test_number";
    return $to_string;
}

sub _build_tap {
    my ( $self, $tap, $name, $test_number ) = @_;

    # I don't want to hardcode this, but it's hardcoded in Test::Builder.
    # Given that I am the one who originally wrote the subtest() code in
    # Test::Builder, this ugliness is my fault - Ovid
    my $indent = '    ';

    my $failed = $self->_tap_failed($tap);
    $tap =~ s/(?<=^)/$indent/gm;
    if ($failed) {
        $tap .= "\nnot ok $test_number - $name\n# $failed\n";
    }
    else {
        $tap .= "\nok $test_number - $name\n";
    }
    return $tap;
}

sub _tap_failed {
    my ( $self, $tap ) = @_;
    my $plan_re = qr/1\.\.(\d+)/;
    my $test_re = qr/(?:not )?ok/;
    my $failed;
    my $core_tap = '';
    foreach ( split "\n" => $tap ) {
        if (/^not ok/) {    # TODO tests are not failures
            $failed++
              unless m/^ ( [^\\\#]* (?: \\. [^\\\#]* )* )
                 \# \s* TODO \b \s* (.*) $/ix
        }
        $core_tap .= "$_\n" if /^(?:$plan_re|$test_re)/;
    }
    my $plan;
    if ( $core_tap =~ /^$plan_re/ or $core_tap =~ /$plan_re$/ ) {
        $plan = $1;
    }
    return 'No plan found' unless defined $plan;
    return "Failed $failed out of $plan tests" if $failed;

    my $plans_found = 0;
    $plans_found++ while $core_tap =~ /^$plan_re/gm;
    return "$plans_found plans found" if $plans_found > 1;

    my $tests = 0;
    $tests++ while $core_tap =~ /^$test_re/gm;
    return "Planned $plan tests and found $tests tests" if $tests != $plan;

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TAP::Stream - Combine multiple TAP streams with subtests

=head1 VERSION

version 0.44

=head1 SYNOPSIS

    use TAP::Stream;
    use TAP::Stream::Text;

    my $tap1 = <<'END';
    ok 1 - foo 1
    ok 2 - foo 2
    1..2
    END

    # note that we have a failing test
    my $tap2 = <<'END';
    ok 1 - bar 1
    ok 2 - bar 2
        1..3
        ok 1 - bar subtest 1
        ok 2 - bar subtest 2
        not ok 3 - bar subtest 3 #TODO ignore
    ok 3 - bar subtest
    not ok 4 - bar 4
    1..4
    END

    my $stream = TAP::Stream->new;

    $stream->add_to_stream(
        TAP::Stream::Text->new( name => 'foo tests', text => $tap1 ),
        TAP::Stream::Text->new( name => 'bar tests', text => $tap2 )
    );

    print $stream->to_string;

Output:

        ok 1 - foo 1
        ok 2 - foo 2
        1..2
    ok 1 - foo tests
        ok 1 - bar 1
        ok 2 - bar 2
            1..3
            ok 1 - bar subtest 1
            ok 2 - bar subtest 2
            not ok 3 - bar subtest 3 #TODO ignore
        ok 3 - bar subtest
        not ok 4 - bar 4
        1..4
    not ok 2 - bar tests
    # Failed 1 out of 4 tests
    1..2

=head1 DESCRIPTION

Sometimes you find yourself needing to merge multiple streams of TAP.
Several use cases:

=over 4

=item * Merging results from parallel tests

=item * Running tests across multiple boxes and fetching their TAP

=item * Saving TAP and reassembling it later

=back

L<TAP::Stream> allows you to do this. You can both merge multiple chunks of
TAP text, or even multiple C<TAP::Stream> objects.

=head1 DESCRIPTION

B<Experimental> module to combine multiple TAP streams.

=head1 METHODS

=head2 C<new>

    my $stream = TAP::Stream->new( name => 'Parent stream' );

Creates a TAP::Stream object. The name is optional, but highly recommend to be
unique. The top-level stream's name is not used, but if you use
C<add_to_stream> to add another stream object, that stream object should be
named or else the summary C<(not) ok> line will be named C<Unnamed TAP stream>
and this may make it harder to figure out which stream contained a failure.

Names should be descriptive of the use case of the stream.

=head2 C<name>

    my $name = $stream->name;

A read/write string accessor.

Returns the name of the stream. Default to C<Unnamed TAP stream>. If you add
this stream to another stream, consider naming this stream for a more useful
TAP output. This is used to create the subtest summary line:

        1..2
        ok 1 - some test
        ok 2 - another test
    ok 1 - this is $stream->name

=head2 C<add_to_stream>

    $stream->add_to_stream(TAP::Stream::Text->new(%args));
    # or
    $stream->add_to_stream($another_stream);

Add a L<TAP::Stream::Text> object or another L<TAP::Stream> object. You may
call this method multiple times. The following two chunks of code are the
same:

    $stream->add_to_stream(
        TAP::Stream::Text->new( name => 'foo tests', text => $tap1 ),
        TAP::Stream::Text->new( name => 'bar tests', text => $tap2 )
    );

Versus:

    $stream->add_to_stream(
        TAP::Stream::Text->new( name => 'foo tests', text => $tap1 ),
    );
    $stream->add_to_stream(
        TAP::Stream::Text->new( name => 'bar tests', text => $tap2 )
    );

Stream objects can be added to other stream objects:

    my $parent = TAP::Stream->new; # the name is unused for the parent

    my $stream = TAP::Stream->new( name => 'child stream' );

    $stream->add_to_stream(
        TAP::Stream::Text->new( name => 'foo tests', text => $tap1 ),
        TAP::Stream::Text->new( name => 'bar tests', text => $tap2 )
    );
    $parent->add_to_stream($stream);

    # later:
    $parent->add_to_stream($another_stream);
    $parent->add_to_stream(TAP::Stream::Text->new%args);
    $parent->add_to_stream($yet_another_stream);

    say $parent->to_string;

=head2 C<to_string>

    say $stream->to_string;

Prints the stream as TAP. We do not overload stringification.

=head1 HOW IT WORKS

Each chunk of TAP (or stream) that is added is added as a subtest. This avoids
issues of trying to recalculate the numbers. This means that if you
concatenate three TAP streams, each with 25 tests, you will still see 3 tests
reported (because you have three subtests).

There is a mini-TAP parser within C<TAP::Stream>. As you add a chunk of TAP or
a stream, the parser analyzes the TAP and if there is a failure, the subtest
itself will be reported as a failure. Causes of failure:

=over 4

=item * Any failing tests (TODO tests, of course, are not failures)

=item * No plan

=item * Number of tests do not match the plan

=item * More than one plan

=back

=head1 CAVEATS

=over 4

=item * Out-of-sequence tests not handled

Currently we do not check for tests out of sequence because, in theory, test
numbers are strictly optional in TAP. Make sure your TAP emitters Do The Right
Thing. Patches welcome.

=item * Partial streams not handled

Each chunk of TAP added must be a complete chunk of TAP, complete with a plan.
You can't add tests 1 through 3, and then 4 through 7.

=back

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

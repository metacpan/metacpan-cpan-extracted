package Options::Generator;

use 5.006;
use strict;
use warnings;
use Carp;

=head1 NAME

Options::Generator - Build options for the command line from a perl data structure

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS


    use Options::Generator;

    my $og = Options::Generator->new;
    print $og->generate($data);
 

    or more detailed...
     
    my $og = Options::Generater->new({
        outer_prefix   => [ '-', '--' ],
        outer_assign   => ' ',  # default
        outer_separate => ' ',  # default
        inner_assign   => '=',  # default
        inner_separate => ',',  # default
        ... 
    });
    my $data = {
        foo => 'bar',
        o =>  undef,
        s =>  'silly',
        options => [ 'one', 'two', { this => that }],
        blah => undef,
    };
    
    prints:

    --foo bar --options one,two,this=that, --blah -o -s silly
    



=head1 SUBROUTINES/METHODS

=head2 Options:Generator->new($args);

Accepts a hashref of definitions

=over 4

=item * outer_prefix
The prefix character to add to the outer options, defaults to a single hyphen if not specified. This is the only option that can accept an array reference for options that are single length. The first element will be assigned to single length options, the second element will be assigned to options greater that a single character.
    outer_prefx => '--' #  --foo
    outer_prefix => '-' #  -foo
    outer_prefix => [ '-', '--'] # -f --foo --bar -s -c 

=item * outer_assign
The character to assign a value to the option, defaults to space if not specified.
    --foo bar
    outer_assign => '='  # --foo=bar

=item * outer_separate
The character to separate outer most options. Defaults to space if not specified.
    --foo bar
    outer_separate => ',' # --foo=bar,--boo=baz

=item * inner_prefx
The prefix character to add to the inner options (if applicable). No prefix by default
    --foo bar,baz,this=that
    inner_prefix => '+' # --foo +bar,+baz,+this=that

=item * inner_assign
The character to assign values to the inner options. Defaults to equals sign.
    --foo this=that,boo=baz

=item * inner_separate
The character to separate inner options. Defaults to comma

Examples of outputs with defaults


    --foo
    --foo --bar
    --foo -b -z --bar
    --foo bar=baz,this=that -o -s --options -f blah



=cut
sub new {
    my $class = shift;
    my $self = {};
    $self = shift if $_[0];

    $self->{inner_prefix}   = defined $self->{inner_prefix}   ? $self->{inner_prefix}   :  '';
    $self->{outer_prefix}   = defined $self->{outer_prefix}   ? $self->{outer_prefix}   : '-';
    $self->{inner_assign}   = defined $self->{inner_assign}   ? $self->{inner_assign}   : '=';
    $self->{outer_assign}   = defined $self->{outer_assign}   ? $self->{outer_assign}   : ' ';
    $self->{inner_separate} = defined $self->{inner_separate} ? $self->{inner_separate} : ',';
    $self->{outer_separate} = defined $self->{outer_separate} ? $self->{outer_separate} : ' ';

    bless $self,$class;
}


=back


=head2 $og->generate($data)

Returns a string of your options.  Supply your perl data structure as a hash ref.
    
    my $data = {
        foo => 'bar',
        bar => 'baz',
        inner => [ 'this', 'that', { one => 'two'} ],
        a => b
        c => undef,
    };
    print $og->generate($hash);


        

=cut
sub generate {
    my ($self,$hash) = @_;
    croak "Need hashref" unless ref $hash eq 'HASH';

    my $build;
    my @outers;
    for my $key (keys %{ $hash }) {

        my $outer;
        if (ref $self->{outer_prefix} eq 'ARRAY') {

            my $outer_prefix = ($key =~ /^\w{1}$/) ? @{ $self->{outer_prefix}}[0] : @{ $self->{outer_prefix}}[1];

            $outer .= $outer_prefix . $key;
        }
        else {
            $outer .= $self->{outer_prefix} . $key;
        }

        my @inners;

        croak "Use array ref for inner options" if (ref $hash->{$key} eq 'HASH');

        if (ref $hash->{$key} eq 'ARRAY') {

            for my $each (@{ $hash->{$key}} ) {

                if (ref $each eq 'HASH') {

                    for my $inner (keys %{ $each }) {
                        my $build .= $self->{inner_prefix} . $inner . $self->{inner_assign} . $each->{$inner};
                        push (@inners,$build);
                    }
                }
                else {
                    push (@inners, $self->{inner_prefix} . $each);
                }
            }
        }
        else {
            push (@inners,$hash->{$key});
        }
        push(@outers,$outer . $self->{outer_assign} .  join($self->{inner_separate}, @inners));
    }
    my $out = join( $self->{outer_separate}, @outers);
    return $out;
}




=head1 AUTHOR

Michael Kroher, C<< <infrared at cpan.org> >>

=head1 BUGS

Wrote this module for kvm-qemu generation stuff (hence the defaults).

Please report any bugs or feature requests to C<bug-commandline-generator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Options-Generator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Options::Generator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Options-Generator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Options-Generator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Options-Generator>

=item * Search CPAN

L<http://search.cpan.org/dist/Options-Generator/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Michael Kroher.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;


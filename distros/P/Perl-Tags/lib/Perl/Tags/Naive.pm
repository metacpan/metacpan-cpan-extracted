package Perl::Tags::Naive;

use strict; use warnings;
use parent 'Perl::Tags';

our $VERSION = '0.32';

=head1 C<Perl::Tags::Naive>

A naive implementation.  That is to say, it's based on the classic C<pltags.pl>
script distributed with Perl, which is by and large a better bet than the
results produced by C<ctags>.  But a "better" approach may be to integrate this
with PPI.

=head2 Subclassing

See L<TodoTagger> in the C<t/> directory of the distribution for a fully
working example (tested in <t/02_subclass.t>).  You may want to reuse parsers
in the ::Naive package, or use all of the existing parsers and add your own.

    package My::Tagger;
    use Perl::Tags;
    use parent 'Perl::Tags::Naive';

    sub get_parsers {
        my $self = shift;
        return (
            $self->can('todo_line'),     # a new parser
            $self->SUPER::get_parsers(), # all ::Naive's parsers
            # or maybe...
            $self->can('variable'),      # one of ::Naive's parsers
        );
    }

    sub todo_line { 
        # your new parser code here!
    }
    sub package_line {
        # override one of ::Naive's parsers
    }

Because ::Naive uses C<can('parser')> instead of C<\&parser>, you
can just override a particular parser by redefining in the subclass. 

=head2 C<get_tags_for_file>

::Naive uses a simple line-by-line analysis of Perl code, comparing
each line against an array of parsers returned by the L<get_parsers> method.

The first of these parsers that matches (if any) will return the
tag/control to be registred by the tagger.

=cut

{
    # Tags that start POD:
    my @start_tags = qw(pod head1 head2 head3 head4 over item back begin
                        end for encoding);
    my @end_tags = qw(cut);

    my $startpod = '^=(?:' . join('|', @start_tags) . ')\b';
    my $endpod = '^=(?:' . join('|', @end_tags) . ')\b';

    sub STARTPOD { qr/$startpod/ }
    sub ENDPOD { qr/$endpod/ }
}

sub get_tags_for_file {
    my ($self, $file) = @_;

    my @parsers = $self->get_parsers(); # function refs

    open (my $IN, '<', $file) or die "Couldn't open file `$file`: $!\n";

    my $start = STARTPOD();
    my $end = ENDPOD();

    my @all_tags;

    while (<$IN>) {
        next if (/$start/o .. /$end/o);     # Skip over POD.
        chomp;
        my $statement = my $line = $_;
        PARSELOOP: for my $parser (@parsers) {
            my @tags = $parser->( 
                $self, 
              $line, 
              $statement,
              $file 
            );
            push @all_tags, @tags;
        }
    }
    return @all_tags;
}

=head2 C<get_parsers>

The following parsers are defined by this module.

=over 4

=cut

sub get_parsers {
    my $self = shift;
    return (
        $self->can('trim'),
        $self->can('variable'),
        $self->can('package_line'),
        $self->can('sub_line'),
        $self->can('use_constant'),
        $self->can('use_line'),
        $self->can('label_line'),
    );
}

=item C<trim>

A filter rather than a parser, removes whitespace and comments.

=cut

sub trim {
    shift;
    # naughtily work on arg inplace
    $_[1] =~ s/#.*//;  # remove comment.  Naively
    $_[1] =~ s/^\s*//; # Trim spaces
    $_[1] =~ s/\s*$//;

    return;
}

=item C<variable>

Tags definitions of C<my>, C<our>, and C<local> variables.

Returns a L<Perl::Tags::Tag::Var> if found

=cut

sub variable {
    # don't handle continuing thingy for now
    my ($self, $line, $statement, $file) = @_;

    return unless $self->{do_variables}; 
        # I'm not sure I see this as all that useful

    if ($self->{var_continues} || $statement =~/^(my|our|local)\b/) {

        $self->{current}{var_continues} = ! ($statement=~/;$/);
        $statement =~s/=.*$//; 
            # remove RHS with extreme prejudice
            # and also not accounting for things like
            # my $x=my $y=my $z;

        my @vars = $statement=~/[\$@%]((?:\w|:)+)\b/g;

        # use Data::Dumper;
        # print Dumper({ vars => \@vars, statement => $statement });

        return map { 
            Perl::Tags::Tag::Var->new(
                name => $_,
                file => $file,
                line => $line,
                linenum => $.,
            ); 
        } @vars;
    }
    return;
}

=item C<package_line>

Parse a package declaration, returning a L<Perl::Tags::Tag::Package> if found.

=cut

sub package_line {
    my ($self, $line, $statement, $file) = @_;

    if ($statement=~/^package\s+((?:\w|:)+)\b/) {
        return (
            Perl::Tags::Tag::Package->new(
                name => $1,
                file => $file,
                line => $line,
                linenum => $.,
            )
        );
    }
    return;
}

=item C<sub_line>

Parse the declaration of a subroutine, returning a L<Perl::Tags::Tag::Sub> if found.

=cut

sub sub_line {
    my ($self, $line, $statement, $file) = @_;
    if ($statement=~/sub\s+(\w+)\b/) {
        return (
            Perl::Tags::Tag::Sub->new(
                name => $1,
                file => $file,
                line => $line,
                linenum => $.,
            )
        );
    }

    return;
}

=item C<use_constant>

Parse a use constant directive

=cut

sub use_constant {
    my ($self, $line, $statement, $file) = @_;
    if ($statement =~/^\s*use\s+constant\s+([^=[:space:]]+)/) {
        return (
            Perl::Tags::Tag::Constant->new(
                name    => $1,
                file    => $file,
                line    => $line,
                linenum => $.,
            )
        );
    }
    return;
}

=item C<use_line>

Parse a use, require, and also a use_ok line (from Test::More).
Uses a dummy tag (L<Perl::Tags::Tag::Recurse> to do so).

=cut

sub use_line {
    my ($self, $line, $statement, $file) = @_;

    my @ret;
    if ($statement=~/^(?:use|require)(_ok\(?)?\s+(.*)/) {
        my @packages = split /\s+/, $2; # may be more than one if base
        @packages = ($packages[0]) if $1; # if use_ok ecc. from Test::More

        for (@packages) {
            s/^q[wq]?[[:punct:]]//;
            /((?:\w|:)+)/;
            $1 and push @ret, Perl::Tags::Tag::Recurse->new( 
                name => $1, 
                line=>'dummy' );
        }
    }
    return @ret;
}

=item C<label_line>

Parse label declaration

=cut

sub label_line {
    my ($self, $line, $statement, $file) = @_;
    if ($statement=~/^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:(?:[^:]|$)/) {
        return (
            Perl::Tags::Tag::Label->new(
                name    => $1,
                file    => $file,
                line    => $line,
                linenum => $.,
            )
        );
    }
    return;
}

=back

=cut

1;

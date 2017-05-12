package Text::TestBase::SubTest;
use strict;
use warnings;
use 5.008001;
use parent qw(Text::TestBase);
use Text::TestBase::SubTest::Node::Block;
use Text::TestBase::SubTest::Node::SubTest;
use Text::TestBase::SubTest::Node::Root;

use Class::Accessor::Lite (
    rw => [qw/subtest_delim/],
);
use Carp ();
our $VERSION = '0.5';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{subtest_delim} = '###';
    $self->{block_class}   = 'Text::TestBase::SubTest::Node::Block';
    return $self;
}

sub parse {
    my ($self, $spec) = @_;
    my $block_delim   = $self->block_delim;
    my $subtest_delim = $self->subtest_delim;
    my $root          = Text::TestBase::SubTest::Node::Root->new;
    my $lineno        = 1;
    my $indent        = do {
        my @m = $spec =~ /^(\s{2,}|\t)/m;
        $m[0] || '    ';
    };

    $spec =~ s/
          ^(
             [ \t]* \Q${subtest_delim}\E.*?
             (?= ^[ \t]* \Q${block_delim}\E | ^[ \t]* \Q${subtest_delim}\E | \z )
           )
        | ^(
             [ \t]* \Q${block_delim}\E .*?
             (?= ^[ \t]* \Q${block_delim}\E | ^[ \t]* \Q${subtest_delim}\E | \z )
           )
        | ^( [^\n]* \n )
    /
        # subtest
        if ($1) {
            my $hunk         = _unindent($1);
            my $subtest      = $self->_make_subtest($hunk, $lineno);
            my $prev_subtest = $root->last_subtest( depth => _depth($1, $indent) - 1 ) || $root;

            $lineno++;
            $prev_subtest->append_child($subtest);

        # block
        } elsif ($2) {
            my $hunk         = _unindent($2);
            my $block        = $self->_make_block($hunk, $lineno);
            my $prev_subtest = $root->last_subtest( depth => _depth($2, $indent) - 1 ) || $root;

            $hunk =~ s!\n!$lineno++!ge;
            $prev_subtest->append_child($block);

        } elsif ($3) {
            $lineno++;
        }
        '';
    /msgxe;

    return $root;
}

sub _make_subtest {
    my ($self, $hunk, $lineno) = @_;
    my $subtest_delim = $self->subtest_delim;
    # TODO:
    #  * common filter
    #  * exception
    my ($name) = $hunk =~ /^$subtest_delim\s+(.+)$/;
    return Text::TestBase::SubTest::Node::SubTest->new(
        name    => $name,
        _lineno => $lineno,
    );
    return $name;
}

sub _unindent {
    my $text = shift;
    my ($indent) = $text =~ /^((?:[ \t])*)/;
    $text =~ s/^$indent//mg;
    return $text;
}

sub _depth {
    my ($str, $indent) = @_;
    my ($captured) = $str =~ /^($indent*)/;
    $captured ||= '';
    return (length($captured) / length($indent)) + 1;
}

1;

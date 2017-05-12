package Pod::Clipper;
use Moose;

use Pod::Clipper::Block;
use Text::Trim;

BEGIN {
    our $VERSION = '0.01';
}

has 'data' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1, 
);

has 'newline_seq' => (
    is       => 'rw',
    isa      => 'Str',
    default  => "\n",
);

has [qw/from_file ignore_whitespace ignore_leading_whitespace ignore_trailing_whitespace/] => (
    is       => 'rw',
    isa      => 'Bool',
);

has 'ignore_invalid_pod' => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 1,
);

has 'append_newline' => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 0,
);

has '_blocks' => (
    is       => 'rw',
    isa      => 'ArrayRef[Pod::Clipper::Block]',
    default  => sub { [] },
    init_arg => undef,
);

sub BUILD {
    my $self = shift;
    $self->_build;
}

sub rebuild {
    my $self = shift;
    $self->_build;
}

sub _build {
    my $self = shift;
    my $nl = $self->newline_seq;
    my $data;
    if ($self->from_file) {
        open(FH, $self->data) or die $!;
        # save those precious bytes of memory! (i.e. no @lines = <FH>;)
        while (<FH>) {
            $data .= $_;
        }
        close(FH);
    }
    else { $data = $self->data; }
    if (!defined($self->ignore_whitespace) || $self->ignore_whitespace) {
        $data = trim($data);
    }
    else {
        $data = ltrim($data) if $self->ignore_leading_whitespace;
        $data = rtrim($data) if $self->ignore_trailing_whitespace;
    }
    my @lines = split $nl, $data;
    my $in_pod = 0;
    my @block;
    undef @{$self->_blocks};
    foreach my $l (@lines) {
        if ($l =~ m/\A=cut/) {
            if (!$in_pod) {
                next if $self->ignore_invalid_pod;
                push @block, $l;
                next;
            }
            $in_pod = 0;
            push @block, $l;
            push @block, '' if $self->append_newline;
            my $b = Pod::Clipper::Block->new({ data => join($nl, @block), is_pod => 1 });
            push @{$self->_blocks}, $b;
            undef @block;
            next;
        }
        if ($l =~ m/\A=[a-zA-Z]/ && !$in_pod) {
            $in_pod = 1;
            if (@block) {
                push @block, '' if $self->append_newline;
                my $b = Pod::Clipper::Block->new({ data => join($nl, @block), is_pod => 0 });
                push @{$self->_blocks}, $b;
                undef @block;
            }
        }
        push @block, $l;
    }
    if (@block) {
        push @block, '' if $self->append_newline;
        my $b = Pod::Clipper::Block->new({ data => join($nl, @block), is_pod => $in_pod });
        push @{$self->_blocks}, $b;
    }
}

sub all {
    my $self = shift;
    return $self->_blocks;
}

sub pod {
    my $self = shift;
    my @pod;
    map { push @pod, $_ if $_->is_pod } @{$self->_blocks};
    return \@pod;
}

sub non_pod {
    my $self = shift;
    my @non_pod;
    map { push @non_pod, $_ if !$_->is_pod } @{$self->_blocks};
    return \@non_pod;
}

=head1 NAME

Pod::Clipper - Extract blocks of POD from a text document

=head1 SYNOPSIS

  use Pod::Clipper;
  my $clipper = Pod::Clipper->new({ data => $data });
  my $all_blocks = $clipper->all;
  foreach (@{$all_blocks}) {
      # do something with $_->data
      if ($_->is_pod) {
          # POD block. do something with the POD data...
          # e.g. convert it to HTML
      }
      else {
          # non-POD block (code etc). do something else with it...
          # e.g. syntax-highlight it
      }
  }

=head1 DESCRIPTION

This module allows you to divide a document/string into POD and non-POD
blocks of text. This is useful for extracting POD data (or code) from a
"mixed" document, like most perl modules on CPAN.

POD data is identified as per the L<perlpodspec|perlpodspec(1)> manpage.
Invalid POD is simply ignored. The only case for this is if a line
matched C</\A=cut/> without a starting POD command (e.g. C<=head1, =head2,>
etc). That line will be completely ignored. If you want such lines to be
included as part of the non-POD blocks, set C<ignore_invalid_pod> to false.

Please note that C<Pod::Clipper> doesn't check the POD data itself for
validity. For example, you may have a mismatched bracket in your POD
like C<CE<lt>E<lt>mismatchedE<gt>>. C<Pod::Clipper> only cares about the
POD commands that mark the beginning and end of your blocks (i.e. where
these blocks should be I<clipped>). It doesn't care about the actual POD
data. Hence, the only case for invalid POD that C<Pod::Clipper> can detect
is if you have a dangling C<=cut> command (explained in the previous
paragraph and L<below|/ignore_invalid_pod>).

By default, leading and trailing whitespace characters are ignored.
To change this, set C<ignore_whitespace> to false.
You can also use C<ignore_leading_whitespace> and
C<ignore_trailing_whitespace> for more control. See below.

=head1 METHODS

=head2 new

This is the C<Pod::Clipper> constructor. As with many perl modules,
configuration options are passed as a hash reference. The available
options are:

=over

=item data

The data you want to process into POD and non-POD blocks. This is a required option.

=item from_file

If this option is set (to true), C<data> is treated as a filename and your
data is pulled from there. If an error occurs (file doesn't exist etc), an
exception will be thrown.

  eval { my $c = Pod::Clipper->new({ data => 'Test.pm', from_file => 1 }); };
  if ($@) {
      # some IO error occurred. the caught error string ($@) is set to
      # whatever perl passed in $! after open() failed
  }

=item newline_seq

The I<line separator> that should be used. The default newline sequence used
to separate lines is C<\n>. In most cases this will do the right thing (perl
treats C<\n> differently depending on what platform it is running on -- see
L<binmode(1)>). However, sometimes you may want to use a different newline
sequence. For example, you're running a script on *nix and trying to read a
file that was created on Windows. In that case, set newline_seq to C<\r\n>
in order to get the correct results. If you're running perl 5.10.x or
newer, you can use C<\R> as your newline sequence and everything should
magically work regardless of where the file was created and what
platform perl is running on.

=item append_newline

By default, C<Pod::Clipper> excludes the last newline character in each
block. For example, if you have the following:

  # line 1
  # line 2
  =pod
  
  test
  
  =cut

C<Pod::Clipper> would divide the text above into these two blocks:

  # line 1
  # line 2 <--- block ends here (no newline)

and

  =pod
  
  test
  
  =cut <--- block ends here (no newline)

If you set C<append_newline> to true, you would get the following blocks
instead:

  # line 1
  # line 2
  <--- block ends here

and

  =pod
  
  test
  
  =cut
  <--- block ends here

Please remember that (the last line of) your data may not necessarily end
with a newline character, so setting C<append_newline> to true may tack an
extra one to the last block.

=item ignore_whitespace

Ignore leading and trailing whitespace characters in your data. Default is
true.

=item ignore_leading_whitespace

Ignore leading whitespace characters in your data. If C<ignore_whitespace>
is set (to true) this option will be ignored.

=item ignore_trailing_whitespace

Ignore trailing whitespace characters in your data. If C<ignore_whitespace>
is set (to true) this option will be ignored.

=item ignore_invalid_pod

Defaults to true which completely ignores "dangling" C<=cut> commands
in the data. Setting this option to false causes such lines to be treated
as non-POD text.

=back

Each of the options listed above also have an accessor/mutator method by
the same name. For example:

  my $data = $clipper->data; # get
  $clipper->data($new_data); # set

=head2 rebuild

If you want to resuse the same C<Pod::Clipper> object for a different
document/string, make sure to call C<rebuild()> after you update your
data and other parameters so that C<all(), pod(),> and C<non_pod()>
return the correct results. For example:

  $clipper->data($new_data);
  $clipper->ignore_whitespace(0);
  $clipper->rebuild; # parse $new_data and build the new blocks
  # $clipper->all now reflects the new data

=head2 all

This method returns an array reference to all blocks, i.e. the POD
and non-POD ones. The order of these blocks as they appear in the
original data is preserved.

=head2 pod

Same as C<all()>, but returns only the POD blocks.

=head2 non_pod

Same as C<all()>, but returns only the non-POD blocks.

=head1 BUGS

There are no known bugs. If you find one, please report it
to me at the email address listed below. Any other suggestions
or comments are also welcome.

=head1 AUTHOR

Yousef H. Alhashemi <yha@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Pod::Clipper::Block|Pod::Clipper::Block>

=cut

1; # leave this here!

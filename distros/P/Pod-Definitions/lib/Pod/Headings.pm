package Pod::Headings;

use strict;
use warnings;

use v5.20;

use Pod::Simple;
our @ISA = qw(Pod::Simple);
our $VERSION = '0.02';

use feature 'signatures';
no warnings 'experimental::signatures';

#
# Can pass a list of handlers to new()
#
sub new ($class, @args) {
    my $self = $class->SUPER::new();
    $self->{handlers} = {@args}; # if scalar @args;
    $self->{_elements} = [];
    return $self;
}

sub _handle_element_start ($parser, $element_name, $attr_hash_r) {

    return unless defined $parser->{handlers}{$element_name};
    push @{$parser->{_elements}}, { heading => $element_name, text => '', attrs=> $attr_hash_r };
}

sub _handle_element_end ($parser, $element_name, $attr_hash_r = undef) {

    return unless scalar @{$parser->{_elements}} && ($element_name eq ${$parser->{_elements}}[-1]->{heading});
    
    my $propagate_text = 0;
    my $this_element = pop @{$parser->{_elements}};
    if (ref $parser->{handlers}{$element_name} eq 'CODE') {
        $propagate_text = $parser->{handlers}{$element_name}->($parser, $element_name, $this_element->{attrs}, $this_element->{text});
    } else {
        $propagate_text = $parser->{handlers}{$element_name};
    }

    if ($propagate_text) {
        if (scalar @{$parser->{_elements}}) {
            ${$parser->{_elements}}[-1]->{text} .= $this_element->{text};
        }
    }

}

sub _handle_text ($parser, $text) {

    ${$parser->{_elements}}[-1]->{text} .= $text if scalar @{$parser->{_elements}};

}

1;

__END__

=head1 NAME

Pod::Headings -- extract headings and paragraphs (and other elements) from Pod

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  my $p = Pod::Headings->new(
    head1 => sub ($parser, $elem, $attrs, $plaintext) {
        print " $elem: $plaintext\n";
        $parser->{_save_head1} = $plaintext;
        undef $parser->{_save_head2};
        $parser->{_save_first_para} = 1;
        1;
    },
    head2 => sub ($parser, $elem, $attrs, $plaintext) {
        print " $elem: $parser->{_save_head1}: $plaintext\n";
        $parser->{_save_head2} = $plaintext;
        $parser->{_save_first_para} = 1;
        1;
    },
    Para => sub ($parser, $elem, $attrs, $plaintext) {
        print " .... text: $plaintext\n" if $parser->{_save_first_para};
        $parser->{_save_first_para} = 0;
        1;
    },
    L => 1,  # Return 0 to drop the plaintext passed to the containing element
    }
  );

=head1 DESCRIPTION

This class is primarily of interest to persons wishing to extract
headings from Pod, as when indexing the functions documented within a
given Pod.

Call new() with a list of elements that your code will handle. Each
element name should be followed either by a true/false value, or by a
coderef which returns true/false.  The truth value determines whether
any plaintext contained in that element will be propagated to the
containing element.

A supplied coderef will be called, at the end of handling the given
element, with four arguments:

=over

=item * A reference to the calling parser object

=item * The name of the element

=item * The attributes of the element (from its opening)

=item * The entire plaintext contained in the element

=back

This is a subclass of L<Pod::Simple> and inherits all its methods.

=head1 SEE ALSO

L<Pod::Simple>

=head1 SUPPORT

This module is managed in an open GitHub repository,
L<https://github.com/lindleyw/Pod-Definitions>. Feel free to fork and
contribute, or to clone and send patches.

=head1 AUTHOR

This module was written and is maintained by William Lindley
<wlindley@cpan.org>.

=cut

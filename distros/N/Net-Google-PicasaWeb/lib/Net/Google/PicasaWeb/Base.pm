package Net::Google::PicasaWeb::Base;
{
  $Net::Google::PicasaWeb::Base::VERSION = '0.12';
}
use Moose;

# ABSTRACT: base class

with 'MooseX::Role::Matcher' => { default_match => 'id' };


has service => (
    is          => 'rw',
    isa         => 'Net::Google::PicasaWeb',
    required    => 1,
    weak_ref    => 1,
);


has twig => (
    is          => 'rw',
    isa         => 'XML::Twig::Elt',
    handles     => {
        xml_text  => 'first_child_text',
    },
);


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Net::Google::PicasaWeb::Base - base class

=head1 VERSION

version 0.12

=head1 DESCRIPTION

This defines some common tools available to many of the classes included with L<Net::Google::PicasaWeb>.

=head1 ATTRIBUTES

These are common attributes shared by subclasses.

=head2 service

This is a link back to the parent L<Net::Google::PicasaWeb> class responsible for communicating with the Picasa Web API.

=head2 twig

This is the L<XML::Twig::Elt> the class was last updated with. This may be used to get more detailed information out of the elements in case there are features of it you want, but this library does not yet provide.

B<Note:> There is no guarantee that future versions of this library will be based upon L<XML::Twig>. As such, you should avoid depending on this if you can.

=head1 METHODS

=head2 xml_text

Given the name of a tag expected in the feed or entry used to define this class, return the text in that element.

This can be helpful at getting into fields passed back from Google that aren't part of the API provided by L<Net::Google::PicasaWeb> (yet). This is only available for objects created by fetching or listing from Google's API.

If you need something more complex than this, you will need to try to use the L</twig> attribute. However, since that attribute is not guaranteed to exist in a future release, use at your own risk. Personally, I'd recommend forking the API on github, patching the code to add the support you want, and submitting a ticket to CPAN RT and beg the author to add it to the next release. If you provide a test, it's very likely your patch will be included quickly.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Sterling Hanenkamp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Template::Plugin::MIME;

use warnings;
use strict;

use base qw( Template::Plugin::Procedural );

use MIME::Entity;
use MIME::Base64;
use Sys::Hostname;
use Digest::SHA;
use Try::Tiny;
use Carp;

BEGIN {
    try {
        require File::LibMagic;
    };
}

=head1 NAME

Template::Plugin::MIME - TemplateToolkit plugin providing a interface to MIME::Entity

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

our $NAME = __PACKAGE__;

=head1 SYNOPSIS

Use this plugin inside a template:

    [% USE MIME %]
    
    [% cid_of_image = MIME.attach('image.png') %]
    
    <img src="cid:[% cid_of_image %]" />

=cut

sub load($$) {
    my ($class, $context) = @_;
    bless {
        _CONTEXT => $context,
    }, $class;
}

sub new($$$) {
    my ($self, $context, $params) = @_;
    unless (ref $self) {
        croak "cannot instanciate myself, consider using $self->load!";
    }
    $context->{$NAME} = {
        attachments => {
            all => [],
            index => {
                files => {},
                cids => {},
            }
        },
        hostname => $params->{hostname} || hostname || 'localhost',
    };
    try {
        $self->{magic} = File::LibMagic->new;
    };
    return $self;
}

sub _context($) { shift()->{_CONTEXT} }

sub base64($$) {
    return encode_base64($_[1]);
}

=head1 METHODS FOR USE OUTSIDE TEMPLATE

=cut

=head2 C<< attachments() >>

Returns all attached files.

    use Template;
    use Template::Plugin::MIME;
    
    $template = Template->new;
    $template->process(...);
    
    $attachments = Template::Plugin::MIME->attachments($template);

=cut

sub attachments($$) {
    my ($self, $template) = @_;
    my $context = $template->context;
    return $context->{$NAME}->{attachments}->{all};
}

=head2 C<< merge($template, $mail) >>

This method merges a L<MIME::Entity|MIME::Entity> documents together with all attached files in the template.

    use Template;
    use Template::Plugin::MIME;
    use MIME::Entity;
    
    $template = Template->new;
    $template->process($infile, $stash, $outfile);
    
    $entity = MIME::Entity->build(
        From => ...,
        To => ...,
        Subject => ...,
        Type => 'text/html',
        Path => $outfile,
    );
    
    Template::Plugin::MIME->merge($template, $entity);
        # $entity is now multipart/related

This methods invokes C< make_multipart('related') > on C< $entity > an then attaches all party to this entity with C< add_part() >.

A more complex example is shown below. This can be used when you want seperate attachement dispositions together:

    use Template;
    use Template::Plugin::MIME;
    use MIME::Entity;
    
    $template = Template->new;
    $template->process($ttfile, $stash, $outfile);
    
    $inner_text = MIME::Entity->build(
        Top => 0, # this is very important!
        Type => 'text/plain',
        Path => $plainfile,
    );
    
    $inner_html = MIME::Entity->build(
        Top => 0, # this is very important!
        Type => 'text/html',
        Path => $outfile,
    );
    
    $outer = MIME::Entity->build(
        From => ...,
        To => ...,
        Subject => ...,
        Type => 'multipart/alternative',
    );
    
    # first, merges the attachments into the html entity:
    Template::Plugin::MIME->merge($template, $inner_html);
        # $inner_html is now multipart/related
    
    # seconds merges the alternative into the root entity:
    $outer->add_part($inner_text);
    $outer->add_part($inner_html);

The advantage is, the root entity considers of two alternative: a plain text and a html variant. the html variant is a multipart too, with related content (images, ...) attached.

And a total complex example shows how to use mixed content:

    use Template;
    use Template::Plugin::MIME;
    use MIME::Entity;
    
    $template = Template->new;
    $template->process($ttfile, $stash, $outfile);
    
    $inner_text = MIME::Entity->build(
        Top => 0, # this is very important!
        Type => 'text/plain',
        Path => $plainfile,
    );
    
    $inner_html = MIME::Entity->build(
        Top => 0, # this is very important!
        Type => 'text/html',
        Path => $outfile,
    );
    
    $outer = MIME::Entity->build(
        Top => 0, # this is very important!
        Type => 'multipart/alternative',
    );
    
    $entity = MIME::Entity->build(
        From => ...,
        To => ...,
        Subject => ...,
        Type => 'multipart/mixed',
    );
    
    # first, merge the attachments into the html entity:
    Template::Plugin::MIME->merge($template, $inner_html);
        # $inner_html is now multipart/related
    
    # second, merge the alternative into the outer entity:
    $outer->add_part($inner_text);
    $outer->add_part($inner_html);
    
    # third, merge all parts together the root entity
    $entity->add_part($outer);
    $entity->add_part(Path => 'invoice.pdf', Type => 'application/pdf', Filename => 'Your Invoice.pdf');

The mime structue is now

    (root) multipart/mixed
    |-> multipart/alternative
    |   |-> multipart/related
    |   |   |-> text/html
    |   |   `-> image/png
    |   `-> text/plain
    `-> application/pdf

=cut

sub merge {
    my ($self, $template, $mail) = @_;
    my $context = $template->context;
    my $attachments = $self->attachments($template);
    
    $mail->make_multipart('related');
    
    foreach my $attachment (@$attachments) {
        $mail->add_part($attachment);
    }
    
    return $mail;
}
   
=head1 FUNCTIONS FOR USE INSIDE TEMPLATE

=head2 C<< attach($path [, %options] ) >>

This method attaches a file and returns a Content-Id for use within html content, for example.

    [% USE MIME %]
    
    [% signature_cid = MIME.attach("signature.png") %]
    
    <img src="cid:[% signature_cid %]" />

The paramhash C<%options> is equivalent to the C<build> class/instance method in L<MIME::Entity|MIME::Entity>. The following options are overridden in order to work with related content:

=over 4

=item * C< Path > is equivalent to C< $path >

=item * C< Id > is the content-id, automatically generated.

=item * C< Encoding > is forced to Base64.

=item * C< Type > is the content type (but see below for more information)

=item * C< Top > is 0, since an attachment is not a top-level entity.

=back

All other options are passed through.

=head3 Obtaining Content-Type

If the Options C< Type > is set, this will be used regardless what the file is really is.

If L<File::LibMagic|File::LibMagic> is installed on your system, C<checktype_filename> will be invoked to obtain the mime-type. This method may fail and error messages are discarded for now.

If all fails, the mime-type "application/octet-stream" is used.

=cut

sub attach($$;$) {
    my ($self, $path, $options) = @_;
    my $context = $self->_context;
    my $this = $context->{$NAME};
    
    if (exists $this->{attachments}->{index}->{files}->{$path}) {
        return $this->{attachments}->{index}->{files}->{$path}->head->get('Content-Id');
    }
    
    unless (-e $path) {
        croak "file '$path' does not exists!";
    }
    
    my $digest = Digest::SHA->new(256);
    $digest->addfile($path) or die $!;
    my $cid = $digest->hexdigest . '@' . $this->{hostname};
    
    if (exists $this->{attachments}->{index}->{cids}->{$cid}) {
        $this->{attachments}->{index}->{files}->{$path} = $this->{attachments}->{index}->{cids}->{$cid};
        return $cid;
    }
    
    my $mimetype = $options->{Type};
    
    try {
        return unless defined $self->{magic};
        $mimetype ||= $self->{magic}->checktype_filename($path);
    } catch {
        carp "libmagic: $_";
    };
    
    $mimetype ||= 'application/octet-stream';
    
    my $part = MIME::Entity->build(
        %$options,
        Path => $path,
        Id => $cid,
        Encoding => 'base64',
        Type => $mimetype,
        Top => 0
    );
    push @{ $this->{attachments}->{all} } => $part;
    $this->{attachments}->{index}->{cids}->{$cid} = $this->{attachments}->{index}->{files}->{$path} = $part;
    return $cid;
}

=head1 AUTHOR

David Zurborg, C<< <david at fakenet.eu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-plugin-mime at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-MIME>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::MIME


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-MIME>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Plugin-MIME>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Plugin-MIME>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Plugin-MIME/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2013 David Zurborg, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the terms of the ISC license.

=cut

1; # End of Template::Plugin::MIME

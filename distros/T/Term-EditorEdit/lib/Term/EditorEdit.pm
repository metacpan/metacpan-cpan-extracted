package Term::EditorEdit;
BEGIN {
  $Term::EditorEdit::VERSION = '0.0016';
}
# ABSTRACT: Edit a document via $EDITOR


# prompt_Yn, prompt_yN

use strict;
use warnings;

use Any::Moose;
use Carp;
use File::Temp;
use Term::EditorEdit::Edit;

sub EDITOR {
    return $ENV{VISUAL} || $ENV{EDITOR};
}

our $__singleton__;
sub __singleton__ {
    return $__singleton__ ||=__PACKAGE__->new;
}

sub edit_file {
    my $self = shift;
    my $file = shift;
    die "*** Missing editor (No \$VISUAL or \$EDITOR)\n" unless my $editor = $self->EDITOR;
    my $rc = system $editor, $file;
    unless ( $rc == 0 ) {
        my ($exit_value, $signal, $core_dump);
        $exit_value = $? >> 8;
        $signal = $? & 127;
        $core_dump = $? & 128;
        die "Error during edit ($editor): exit value($exit_value), signal($signal), core_dump($core_dump): $!";
    }
}

sub edit {
    my $self = shift;
    $self = $self->__singleton__ unless blessed $self;
    my %given = @_;
    # carp "Ignoring remaining arguments: @_" if @_;

    my $document = delete $given{document};
    $document = '' unless defined $document;

    my $file = delete $given{file};
    $file = $self->tmp unless defined $file;

    my $edit = Term::EditorEdit::Edit->new(
        editor => $self,
        file => $file,
        document => $document,
        %given, # process, split, ...
    ); 

    return $edit->edit;
}

sub tmp { return File::Temp->new( unlink => 1 ) }

1;

__END__
=pod

=head1 NAME

Term::EditorEdit - Edit a document via $EDITOR

=head1 VERSION

version 0.0016

=head1 SYNOPSIS

    use Term::EditorEdit;
    
    # $VISUAL or $EDITOR is invoked
    $document = Term::EditorEdit->edit( document => <<_END_ );
    Apple
    Banana
    Cherry
    _END_

With post-processing:

    $document = Term::EditorEdit->edit( document => $document, process => sub {
        my $edit = shift;
        my $document = $edit->document;
        if ( document_is_invalid() ) {
            # The retry method will return out of ->process immediately (via die)
            $edit->retry
        }
        # Whatever is returned from the processor will be returned via ->edit
        return $document;
    } );

With an "out-of-band" instructional preamble:

    $document = <<_END_
    # Delete everything but the fruit you like:
    ---
    Apple
    Banana
    Cherry
    _END_

    # After the edit, only the text following the first '---' will be returned
    $content = Term::EditorEdit->edit(
        separator => '---',
        document => $document,
    );

=head1 DESCRIPTION

Term::EditorEdit is a tool for prompting the user to edit a piece of text via C<$VISUAL> or C<$EDITOR> and return the result

In addition to just editing a document, this module can distinguish between a document preamble and document content, giving you a way to provide "out-of-bound" information to whoever is editing. Once an edit is complete, only the content (whatever was below the preamble) is returned

=head1 USAGE

=head2 $result = Term::EditorEdit->edit( ... )

Takes the following parameters:

    document            The document to edit (required)

    separator           The string to use as a line separator dividing
                        content from the preamble

    process             A code reference that will be called once an edit is complete.
                        Within process, you can check the document, preamble, and content.
                        You can also have the user retry the edit. Whatever is returned
                        from the code will be what is returned from the ->edit call

Returns the edited document (or content if a separator was specified) or the result of
the C<process> argument (if supplied)

=head1 SEE ALSO

L<Term::CallEditor>

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


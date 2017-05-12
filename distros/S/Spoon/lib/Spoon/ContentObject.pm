package Spoon::ContentObject;
use Spoon::DataObject -Base;

stub 'content';
stub 'metadata';
const is_readable => 1;
const is_writable => 1;

sub force {
    if (@_) {
        $self->{force} = shift;
        return $self;
    }
    $self->{force} ||= 0;
}

sub database_directory {
    join '/', $self->hub->config->database_directory, $self->class_id; 
}

sub file_path {
    join '/', $self->database_directory, $self->id;
}

sub exists {
    -e $self->file_path;
}

sub deleted {
    -z $self->file_path;
}

sub active {
    return $self->exists && not $self->deleted;
}

sub assert_readable {
    if (not $self->is_readable) {
        my $id = $self->id;
        die "$id is not readable";
    }
}

sub assert_writable {
    if (not $self->is_writable) {
        my $id = $self->id;
        die "$id is not writable";
    }
}

sub load {
    $self->load_content;
    $self->load_metadata;
    return $self;
}

sub load_content {
    $self->assert_readable;
    my $content = $self->active
    ? io($self->file_path)->utf8->all
    : '';
    $self->content($content);
    return $self;
}

sub load_metadata {
    my $metadata = $self->{metadata}
      or die "No metadata object in content object";
    $metadata->load;
    return $self;
}

sub store {
    $self->assert_writable;
    $self->store_content or return;
    $self->store_metadata;
    return if $self->force;
    return $self;
}

sub store_content {
    my $content = $self->content;
    if ($content) {
        $content =~ s/\r//g;
        $content =~ s/\n*\z/\n/;
    }
    my $file = io->file($self->file_path)->utf8;
    unless ($self->force) {
        return if $file->exists and 
                  $content eq $file->all;
    }
    $file->print($content);
    return $self;
}

sub store_metadata {
    my $metadata = $self->{metadata}
      or die "No metadata for content object";
    $metadata->store;
    return $self;
}

__DATA__

=head1 NAME 

Spoon::ContentObject - Spoon Content Object Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

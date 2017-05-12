package Reply::Plugin::Editor;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::Editor::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: command to edit the current line in a text editor

use base 'Reply::Plugin';

use File::HomeDir;
use File::Spec;
use Proc::InvokeEditor;


sub new {
    my $class = shift;
    my %opts = @_;

    my $self = $class->SUPER::new(@_);
    $self->{editor} = Proc::InvokeEditor->new(
        (defined $opts{editor}
            ? (editors => [ $opts{editor} ])
            : ())
    );
    $self->{current_text} = '';

    return $self;
}

sub command_e {
    my $self = shift;
    my ($line) = @_;

    my $text;
    if (length $line) {
        if ($line =~ s+^~/++) {
            $line = File::Spec->catfile(File::HomeDir->my_home, $line);
        }
        elsif ($line =~ s+^~([^/]*)/++) {
            $line = File::Spec->catfile(File::HomeDir->users_home($1), $line);
        }

        my $current_text = do {
            local $/;
            if (open my $fh, '<', $line) {
                <$fh>;
            }
            else {
                warn "Couldn't open $line: $!";
                return '';
            }
        };
        $text = $self->{editor}->edit($current_text, '.pl');
    }
    else {
        $text = $self->{editor}->edit($self->{current_text}, '.pl');
        $self->{current_text} = $text;
    }

    return $text;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::Editor - command to edit the current line in a text editor

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [Editor]
  editor = emacs

=head1 DESCRIPTION

This plugin provides the C<#e> command. It will launch your editor, and allow
you to edit bits of code in your editor, which will then be evaluated all at
once. The text you entered will be saved, and restored the next time you enter
the command. Alternatively, you can pass a filename to the C<#e> command, and
the contents of that file will be preloaded instead.

The C<editor> option can be specified to provide a different editor to use,
otherwise it will use the value of C<$ENV{VISUAL}> or C<$ENV{EDITOR}>.

=for Pod::Coverage command_e

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut

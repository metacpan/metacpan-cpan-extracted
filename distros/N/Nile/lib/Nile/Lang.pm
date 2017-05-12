#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Lang;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Lang - Language file manager.

=head1 SYNOPSIS
    
    $lang = $self->app->lang;
    
    # load language file from the current active or default language, file extension is xml.
    $lang->load("general");

    # load and append another language file
    $lang->load("accounts");
    
    # load language file of specific language.
    $lang->load($file, $lang);

    # get language variables from the active langauge
    say $lang->get("site_name");
    say $lang->get("first_name");
    say $lang->get("last_name");
        
    # get language variables of specific installed language.
    say $lang->get("site_name", 'en-US');

    # automatic getter support
    say $lang->email; # same as $lang->get('email');

    # get a group of language variables.
    @text = $lang->list(@names);

    # set language variables.
    $lang->set("email_label", 'Email:');
    $lang->set(%vars);

    # automatic setter support
    $lang->email('ahmed@mewsoft.com'); # same as $lang->set('email', 'ahmed@mewsoft.com');

=head1 DESCRIPTION

Nile::Lang - Language file manager.

=cut

use Nile::Base;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 file()
    
    # set output file name for saving
    $lang->file($file);

    # get output file name
    $file = $lang->file();

Get and set the output language file name used when saving or updating. The default file extension is xml.

=cut

has 'file' => (
    is          => 'rw',
  );

=head2 encoding()
    
    # get encoding used to read/write the language files, default is 'UTF-8'.
    $encoding = $lang->encoding();
    
    # set encoding used to read/write the langauge files, default is 'UTF-8'.
    $lang->encoding('UTF-8');

Get and set encoding used to read/write the language files. The default encoding is 'UTF-8'.

=cut

has 'encoding' => (
    is          => 'rw',
    default => 'UTF-8',
  );

 has 'files' => (
        is => 'rw',
        isa => 'HashRef',
        default => sub { +{} }
    );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub AUTOLOAD {
    
    my ($self) = shift;

    my ($class, $method) = our $AUTOLOAD =~ /^(.*)::(\w+)$/;

    if ($self->can($method)) {
        return $self->$method(@_);
    }

    if (@_) {
        $self->{vars}->{$self->{lang}}->{$method} = $_[0];
    }
    else {
        return $self->{vars}->{$self->{lang}}->{$method};
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 load()
    
    # load language file from the current active or default language, file extension is xml.
    $lang->load("general");

    # load and append another language file
    $lang->load("accounts");
    
    # load language file of specific language.
    $lang->load($file, $lang);

Load language files from the current active or specific language. The default file extension is xml.
This method can be chained C<$lang->load($file)->load($register)>;

=cut

sub load {
    
    my ($self, $file, $lang) = @_;
    my $app = $self->app;

    $lang ||= $self->{lang} ||= $app->var->get("lang");

    # file already loaded
    if ($self->files->{$lang}->{$file}) {
        return $self;
    }
    
    my $origfile = $file;

    $file .= ".xml" unless ($file =~ /\.xml$/i);

    my $filename = $app->file->catfile($app->var->get("langs_dir"), $lang, $file);
    
    my $xml = $app->xml->get_file($filename);

    $self->{vars}->{$lang} ||= +{};
    $self->{vars}->{$lang} = {%{$self->{vars}->{$lang}}, %$xml};

    $self->file($file);
    $self->files->{$lang}->{$origfile} = 1;

    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 add()
    
    # load a list of language files from the current active or default language, file extension is xml.
    $lang->add("general", "register", "contact");

Load a list of language files from the current active or specific language. The default file extension is xml.
This method can be chained C<$lang->load($file, $lang)->add(@files)>;

=cut

sub add {
    my ($self, @files) = @_;
    $self->load($_) for @files;
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 reload()
    
    # reload a list of language files from the current active or default language, file extension is xml.
    $lang->reload("general", "register");

Reload a list of language files from the current active or specific language. The default file extension is xml.
This method can be chained.

=cut

sub reload {
    my ($self, @files) = @_;
    foreach (@files) {
        delete $self->files->{$self->lang}->{$_};
        $self->load($_);
    }
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 lang()
    
    # get active language for the language object.
    $lang = $lang->lang();

    # set active language for the language object.
    $lang->lang("en-US");
    
Get and set active language used when loading or writing the language files.

=cut

sub lang {
    my ($self, $lang) = @_;
    $self->{lang} = $lang if ($lang);
    $self->{lang} ||= $self->app->var->get("lang");
    return $self->{lang};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 clear()
    
    # clear all loaded language data.
    $lang = $lang->clear();

    # clear all loaded language data of sepcific language.
    $lang->clear("en-US");
    
Clear all loaded language data or sepcific language or all languages. This does not delete the data from files.

=cut

sub clear {
    my ($self, $lang) = @_;
    ($lang)? $self->{vars}->{$lang} = +{} : $self->{vars} = +{};
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 vars()
    
    # get all loaded language data as hash or hash ref.
    %data = $lang->vars();
    $data_ref = $lang->vars();

    # get all loaded language data of sepcific language as hash or hash ref.
    %data = $lang->vars("en-US");
    $data_ref = $lang->vars("en-US");
    
Returns all loaded language data as a hash or hash reference of sepcific language or all languages.

=cut

sub vars {
    my ($self, $lang) = @_;
    if ($lang) {
        return wantarray? %{$self->{vars}->{$lang}} : $self->{vars}->{$lang};
    }
    else {
        return wantarray? %{$self->{vars}} : $self->{vars};
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 get()
    
    # get language variables from the active langauge
    say $lang->get("site_name");
    say $lang->get("first_name");
    say $lang->get("last_name");
        
    # get language variables of specific installed language.
    say $lang->get("site_name", 'en-US');

    # automatic getter support
    say $lang->email; # same as $lang->get('email');

Returns language variables from the active or specific installed language.

=cut

sub get {
    my ($self, $name, $lang) = @_;
    $lang ||= $self->{lang} ||= $self->app->var->get("lang");
    $self->{vars}->{$lang}->{$name};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 set()
    
    # set language variables.
    $lang->set("email_label", 'Email:');
    $lang->set(%vars);

    # automatic setter support
    $lang->email('ahmed@mewsoft.com'); # same as $lang->set('email', 'ahmed@mewsoft.com');

Set language variables of the active language.

=cut

sub set {
    my ($self, %vars) = @_;
    map {$self->{vars}->{$self->{lang}}->{$_} = $vars{$_}} keys %vars;
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 list()
    
    # get a list of language variables.
    @text = $lang->list(@names);

Set a list of  language variables from the active language.

=cut

sub list {
    my ($self, @n) = @_;
    @{$self->{vars}->{$self->{lang}}}{@n};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 keys()
    
    # returns all language variables names.
    @names = $lang->keys($);

Returns all language variables names.

=cut

sub keys {
    my ($self) = @_;
    (keys %{$self->{vars}->{$self->{lang}}});
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 exists()
    
    # check if a langugage variable exist or not.
    $found = $lang->exists($name);

Check if a langugage variable exist or not.

=cut

sub exists {
    my ($self, $name) = @_;
    exists $self->{vars}->{$self->{lang}}->{$name};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 delete()
    
    # delete langugage variables.
    $lang->delete(@names);

Delete a list of language variables.

=cut

sub delete {
    my ($self, @n) = @_;
    delete $self->{vars}->{$self->{lang}}->{$_} for @n;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 get_file()
    
    # returns language file data from the active or default language, default file extension is xml.
    %data = $lang->get_file("contacts");
    $data_ref = $lang->get_file("contacts");

    # returns language file data from specific language, default file extension is xml.
    %data = $lang->get_file("contacts", "en-US");
    $data_ref = $lang->get_file("contacts", "en-US");

Returns language file data as a hash or hash reference from the active or specific language. The default file extension is xml.

=cut

sub get_file {
    
    my ($self, $file, $lang) = @_;
    my $app = $self->app;

    $file .= ".xml" unless ($file =~ /\.xml$/i);
    $lang ||= $self->{lang} ||= $app->var->get("lang");

    my $filename = $app->file->catfile($app->var->get("langs_dir"), $lang, $file);

    my $xml = $app->xml->get_file($filename);
    
    return wantarray? %{$xml} : $xml;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 save()
    
    # write the output file.
    $lang->save($file);

Save changes to the output file. If no file name it will update the loaded file name.

=cut

sub save {
    my ($self, $file) = @_;
    my $app = $self->app;
    $file ||= $self->file;
    $file .= ".xml" unless ($file =~ /\.xml$/i);
    my $filename = $app->file->catfile($app->var->get("langs_dir"), $self->{lang}, $file);
    $app->xml->writefile($filename, $self->{vars}->{$self->{lang}}, $self->encoding);
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 translate()
    
    # scan and replace the language variables $passes times in language $lang
    $content = $lang->translate($content, $lang, $passes) 
    
    # pass content by ref for better speed
    $lang->translate(\$content, $lang, $passes) 
    
    # use current language and default passes
    $content = $lang->translate($content);
    $lang->translate(\$content);

    # use specific language and passes
    $lang->translate($content, "en-US", 3);

Translate language variables inside contents to their language values. It scans the content for the langauge variables
surrounded by the curly braces B<{var_name}> and replaces them with their values from the loaded language files.

=cut

sub translate {
    
    my ($self, $text, $lang, $passes) = @_;
    
    my $content = ref($text) ? $text: \$text;
    
    #   at least should be 2 passes for variables inside variables
    $passes += 0;
    $passes ||= 2;
    
    if (!defined ($lang) and $lang ne "") {
        $lang = $self->{lang};
    }
    
    my $vars = $self->{vars}->{$lang};

    while ($passes--) {
        # If you knew ahead of time the string was a word character for example you might try \w{1,} instead 
        # of .+? to squeeze a tiny bit more speed out of this
        $$content =~ s/\{(.+?)\}/exists $vars->{$1} ? $vars->{$1} : "\{$1\}"/gex;
        #$self->{content} =~ s{\{(.+?)\}(?(?{exists $vars->{$1}})(*SKIP)(*FAIL))}{$vars->{$1}}gx; # Perl 5.10, slower 11%
    }

    if (!ref($text)) {
        return $$content;
    }

    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 translate_file()
    
    $content = $lang->translate_file($file, $lang, $passes);
    
    # use current langauge and default passes
    $content = $lang->translate_file($file);
    $content = $lang->translate_file($file, $lang);

Loads and translates a file. The $file argument must be the full system file path.

=cut

sub translate_file {
    my ($self, $file, $lang, $passes) = @_;
    return $self->translate($self->app->file->get($file), $lang, $passes);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub DESTROY {
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

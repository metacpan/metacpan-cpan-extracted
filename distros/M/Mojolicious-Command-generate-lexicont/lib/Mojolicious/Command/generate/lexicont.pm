package Mojolicious::Command::generate::lexicont;
use 5.008005;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Command';
use Config::PL;
use Carp;
use Encode qw/decode/;
use Module::Load;

__PACKAGE__->attr(description => <<'EOF');
Generate lexicon file translations.
EOF

__PACKAGE__->attr(usage => <<"EOF");
usage: APPLICATION generate lexicont src_lang dest_lang ...
EOF

__PACKAGE__->attr('conf_file');
__PACKAGE__->attr('conf');

our $VERSION = "0.05";


sub run {
    my $self      = shift;
    
    my $arg_num = @_;

    if ($arg_num < 2){
        croak $self->usage;
    }

    my $src_lang  = shift;

    my $app;
    if (ref $self->app eq 'CODE'){
        $app = $self->app->();
    }
    else{
        $app = $self->app;
    }
    my $app_class = ref $app;
    $app_class =~ s{::}{/}g;
    my $app_klass = ref $app;

    my $verbose;

    my @dest_langs = @_;

    my $src_file = $app->home->rel_file("lib/$app_class/I18N/${src_lang}.pm");
    my $org_file = $app->home->rel_file("lib/$app_class/I18N/org.pm");

    if ( ! -e $org_file && ! -e $src_file) {
        croak <<NOTFOUND;
Src lexicon not found $src_file
NOTFOUND
    }

    my %srclex = ();
    
    if (-e $src_file){
        %srclex = eval {
            require "$app_class/I18N/${src_lang}.pm";
            no strict 'refs';
            %{*{"${app_klass}::I18N::${src_lang}::Lexicon"}};
        };            
        if ($@){
            croak( "error $@" );
        }
    }

    my $conf_file = $self->conf_file || "lexicont.conf";
    my $conf;
    eval{
        $conf = config_do $conf_file;
    };
    if ($@){
        croak "Config file cannot read $@ ($conf_file)"
    }

    $self->conf($conf);

    if (-e $org_file) {

        my %orglex = eval {
            require "$app_class/I18N/org.pm";
            no strict 'refs';
            %{*{"${app_klass}::I18N::org::Lexicon"}};
        };            
        if ($@){
            croak( "error $@" );
        }

        my %changes = ();
        
        for my $key (%orglex){
            if ( defined $srclex{$key} && ($orglex{$key} ne $srclex{$key})){ 
                $changes{$key} = 1;
            }
        }

        for my $dest_lang (@dest_langs){

            my $dest_file = $app->home->rel_file("lib/$app_class/I18N/${dest_lang}.pm");

            my %destlex = ();
            if ( -e $dest_file){
                %destlex = eval {
                    require "$app_class/I18N/${dest_lang}.pm";
                    no strict 'refs';
                    %{*{"${app_klass}::I18N::${dest_lang}::Lexicon"}};
                };            
                if ($@){
                    croak( "error $@" );
                }
            }

            my %lexicon = ();

            for my $key (keys %orglex){
                if ( ! defined $srclex{$key} || (defined $changes{$key} && $changes{$key} == 1)){ 
                    $lexicon{$key} = $self->translate( $src_lang, $dest_lang, $orglex{$key});
                }
                else{
                    $lexicon{$key} = $destlex{$key};
                }
            }

            # Output lexem
            $self->render_to_file('package', $dest_file, $app_klass, $dest_lang,
                \%lexicon);

            if ( defined $conf->{json} && $conf->{json} == 1 ){
                my $dest_json = $app->home->rel_file("public/${dest_lang}.json");

                # Output json
                $self->render_to_file('json', $dest_json, $app_klass, $dest_lang,
                    \%lexicon);
            }

        }

        my %utf8_orglex = map { $_ => (utf8::is_utf8 ($orglex{$_})) ? $orglex{$_} : decode("utf8", $orglex{$_})} keys %orglex;
        my $src_file = $app->home->rel_file("lib/$app_class/I18N/${src_lang}.pm");
        $self->render_to_file('package', $src_file, $app_klass, $src_lang,
                \%utf8_orglex);

        if ( defined $conf->{json} && $conf->{json} == 1 ){

            my $dest_json = $app->home->rel_file("public/${src_lang}.json");

            # Output json
            $self->render_to_file('json', $dest_json, $app_klass, $src_lang,
                \%utf8_orglex);

        }

    }
    else{

        for my $dest_lang (@dest_langs){

            my $dest_file = $app->home->rel_file("lib/$app_class/I18N/${dest_lang}.pm");

            my %lexicon = map { $_ => $self->translate( $src_lang, $dest_lang, $srclex{$_}) } keys %srclex;

            # Output lexem
            $self->render_to_file('package', $dest_file, $app_klass, $dest_lang,
                \%lexicon);

            if ( defined $conf->{json} && $conf->{json} == 1 ){

                my $dest_json = $app->home->rel_file("public/${dest_lang}.json");

                # Output json
                $self->render_to_file('json', $dest_json, $app_klass, $dest_lang,
                    \%lexicon);
            }

        }

        if ( defined $conf->{json} && $conf->{json} == 1 ){

            my $dest_json = $app->home->rel_file("public/${src_lang}.json");

            my %utf8_srclex = map { $_ => (utf8::is_utf8 ($srclex{$_})) ? $srclex{$_} : decode("utf8", $srclex{$_})} keys %srclex;

            # Output json
            $self->render_to_file('json', $dest_json, $app_klass, $src_lang,
                \%utf8_srclex);

        }

    }

}

sub translate{

    my $self = shift;
    my $src = shift;
    my $dest = shift;
    my $text = shift;

    my $xl8r;

    eval{
        my $back_end = $self->conf->{lingua_translate}->{back_end};
        my $klass = "Lingua::Translate::" . $back_end;
        load($klass);
        $xl8r  = $klass->new(%{$self->conf->{lingua_translate}}, src => $src, dest => $dest);
    };
    if ($@){
        croak "Lingua::Translate create error $@";
    }
    
    my $trans_text = '';

    eval{
        $trans_text = $xl8r->translate($text);
        if (defined $self->conf->{sleep}){
            sleep( $self->conf->{sleep} );
        }
    };
    if ($@){
        warn ("Cannot translate $@");
    }
    return $trans_text;

}

1;

__DATA__
@@ package
% my ($app_class, $language, $lexicon) = @_;
package <%= $app_class %>::I18N::<%= $language %>;
use base '<%= $app_class %>::I18N';
use utf8;

our %Lexicon = (
% foreach my $lexem (sort keys %$lexicon) {
    % my $data = $lexicon->{$lexem} || '';
    % $lexem=~s/'/\\'/g;
    % utf8::encode $data;
    % $data =~s/'/\\'/g;
    % if( $data =~ s/\n/\\n/g ){
    %   $data = '"' . $data . '"';
    % } else {
    %   $data = "'${data}'";
    % }
    % unless ($lexem=~s/\n/\\n/g) {
    '<%= $lexem %>' => <%= $data %>,
    % } else {
    "<%= $lexem %>" => <%= $data %>,
    % };
% }
);

1;

@@ json
% my ($app_class, $language, $lexicon) = @_;
{
% my $first = 0;
% foreach my $lexem (sort keys %$lexicon) {
    %= ($first++ == 0)? "" : "," 
    % my $data = $lexicon->{$lexem} || '';
    % $lexem=~s/"/\\"/g;
    % utf8::encode $data;
    % $data =~s/"/\\"/g;
    % if( $data =~ s/\n/\\n/g ){
    %   $data = '"' . $data . '"';
    % } else {
    %   $data = "\"${data}\"";
    % }
    % unless ($lexem=~s/\n/\\n/g) {
    "<%= $lexem %>" : <%= $data %>
    % } else {
    "<%= $lexem %>" : <%= $data %>
    % };
% }
}
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Command::generate::lexicont - Mojolicious Lexicon Translation Generator

=head1 SYNOPSIS

    # You write en.pm and generate fr.pm
    # All the lexicon described in en.pm will translate.
    ./script/my_app generate lexicont en fr
    
    # You write en.pm and generate de.pm, fr.pm and ru.pm.
    # All the lexicon described in en.pm will translate.
    ./script/my_app generate lexicont en de fr ru

    # You write org.pm and generate en.pm, de.pm, fr.pm and ru.pm.
    # Difference between org.pm and en.pm will translate.
    ./script/my_app generate lexicont en de fr ru

=head1 DESCRIPTION

Mojolicious::Command::generate::lexicont is lexicon translation generator.

Mojolicious::Plugin::I18N is standard I18N module for Mojolicious.
For example English, you must make lexicon file in the package Myapp::I18N::en.
This module is lexicon file generator from one language to specified languages using
Lingua::Translate. So you can customize translation service.

It is not convenient every time all the lexicons are translated.
Write the lexicon in the package Myapp::I18N::org, and generate only difference parts.

Support front end JavaScript lexicon library l10n.js <https://github.com/eligrey/l10n.js/>
If you want to generate a lexicon file of l10n.js , please attach a json option in the configuration file.

=head1 CONFIGURATION

Create config file lexicont.conf on your project home directory.

#InterTran

{
    lingua_translate => {
      back_end => "InterTran",
    },
    sleep => 5,
}

sleep parameter is for access interval.

#Bing

{
    lingua_translate => {
        back_end => "BingWrapper",
        client_id => "YOUR_CLIENT_ID", 
        client_secret => "YOUR_CLIENT_SECRET"
    }
}


#Google

{
    lingua_translate => {
        back_end => "Google",
        api_key => "YOUR_API_KEY", 
    }
}

#Google with JSON lexicon output

{
    lingua_translate => {
        back_end => "Google",
        api_key => "YOUR_API_KEY", 
    },
    json => 1
}


=head1 LICENSE

Copyright (C) dokechin.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

dokechin E<lt>E<gt>

=cut


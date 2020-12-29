package Mojolicious::Plugin::AssetPack::Pipe::VueTemplateCompiler;
use Mojo::Base 'Mojolicious::Plugin::AssetPack::Pipe';
use Mojolicious::Plugin::AssetPack::Util qw(diag $CWD DEBUG checksum);
use Mojo::Util qw(url_unescape decode);

has config => sub { my $self = shift; my $config = $self->assetpack->config || $self->assetpack->config({}); $config->{VueTemplateCompiler} ||= {} };
has enabled => sub { shift->config->{enabled} || 0 };
#~ has parceljs => sub { [qw(parcel build --no-cache )] };#--out-file --out-dir
#~ has parceljs => "/tmp/node_modules/parcel-bundler/bin/cli.js"; #--out-file --out-dir
#~ has compiler => sub { Mojo::File->new(__FILE__)->sibling('vue-template-compiler.js') };
has revision => sub { shift->assetpack->revision // '' };
has _compiler => sub {
  my $self = shift;
  my $bin = Mojo::Loader::data_section(__PACKAGE__, 'vue-template-compiler.js');
  my $tmp = Mojo::File::tempfile(SUFFIX => '.js');
  $tmp->spurt($bin);
  #~ return [$self->_find_app([qw(nodejs node)]), $tmp->realpath];
};


sub process {
  my ($self, $assets) = @_;

  #~ my $topic = $self->topic;
  #~ my $topicURL  = Mojo::URL->new($topic);
  my $topicURL  = Mojo::URL->new($self->topic);
  my $topic =  url_unescape($topicURL->path->to_string);
  my $format = $topicURL->path->[-1] =~ /\.(\w+)$/ ? lc $1 : '';
  
  return 
    unless $format eq 'js';
  
  my $checksum = checksum $topic.$self->revision;#
  my $store = $self->assetpack->store;
  my $attrs = {key => "js-vue-template", url=>$topic, name=>decode('UTF-8', $topic), checksum=>$checksum, minified=>1, format=>$format,};# for store
  
  if ($self->assetpack->minify || !$self->enabled) {# production loads development
    #~ my $asset = $store->load($attrs)
    my $file = Mojo::File->new($self->app->static->paths->[0], $topic);
    splice @$assets, 0, scalar @$assets,
      Mojolicious::Plugin::AssetPack::Asset->new(url => $topic)->checksum($checksum)->minified(1)
      ->content($file->slurp)
      if -f $file;
    return;
  }
  
  my @content = ();
  $assets->each(
    sub {
      my ($asset, $index) = @_;
      return
       if $asset->format ne 'html' || $asset->minified;
      
      return
        unless $asset->name =~ /\.vue$/;
      
      $asset->format('js');
      my $attrs = $asset->TO_JSON;
      $attrs->{key}      = 'js-vue-template';
      $attrs->{minified} = 1;
      #~ $attrs->{name} = $attrs->{checksum};
      my $url = url_unescape(Mojo::URL->new($asset->url)->path->to_string);
      #~ my $file = $asset->path; #Mojo::File
      #~ my $tmp_file_vue = $file->copy_to($file->new("/tmp/".$asset->name));#
      #~ DEBUG &&  
      diag "Compile Vue Template: [%s] to topic [%s] ", $url, $topic;#$self->assetpack->app->dumper($asset);#, $file->stat->size;join("", map(("$_=>"=>$attrs->{$_}), keys %$attrs))
  
      local $CWD = "/tmp";#$self->app->home->to_string;
      
     #~ local $ENV{NODE_ENV}  = $self->app->mode;
    local $ENV{NODE_PATH} = '/tmp/node_modules';#$self->app->home->rel_file('node_modules');
   
    
    #~ my $tmp_vue = $asset->path->copy_to(Mojo::File->new("/tmp/".$asset->name));#
      #~ $self->run(['node', $self->parceljs, 'build', ' --no-cache', '--out-file', $tmp_vue->path.'.js', '--out-dir', '.', $tmp_vue->path,  ], undef, undef,);# \my $content
      #~ my $js = Mojo::File->new($tmp_vue->path.'.js');
      #~ diag sprintf qq|"%s":function(){%s}|, $asset->url, $self->_parse_render_function($js->slurp);
      #~ my $content = sprintf qq|"%s":function(){%s}|, $url, $self->_parse_render_function($js->slurp);
      #~ my $content = sprintf qq|parcelRequire.register("%s", {%s});|, $url, $self->_parse_render_function($js->slurp);
      #~ $tmp_vue->remove;
      #~ $js->remove;
      
      $self->_install_node_modules('vue-template-compiler', '@vue/component-compiler-utils');
      $self->run([$self->_find_app([qw(nodejs node)]), $self->_compiler->realpath], \$asset->content, \my $content);
      $content = sprintf qq|parcelRequire.register("%s", (function(){%s; return {render,staticRenderFns};})());|, $url, $content;
      push @content, $content;
      $asset->content($store->save(\$content, $attrs)->minified(1));
    }
  );
  
  return
    unless scalar @content;
  
  my $content = join "\n", @content;
  $self->_save_topic($topic, $content);
  
  #~ my $asset = Mojolicious::Plugin::AssetPack::Asset->new(url => $topic)->checksum($checksum)->minified(1)
      #~ ->content($content);

  Mojo::File::path($self->app->static->paths->[0], 'cache', $topic)->dirname->make_path;
  #~ $self->assetpack->{by_checksum}{$checksum} 
  my $asset = $store->save(\$content, $attrs);#decode('UTF-8', $topic)
  $self->assetpack->{by_topic}{$topic} = [$asset];
}

sub _save_topic {
  my ($self, $topic, $content) = @_;
  my $path = Mojo::File::path($self->app->static->paths->[0], $topic);
  DEBUG && diag "Save Vue compiled topic [%s]", $path;
  $path->dirname->make_path;
  $path->spurt($content);
}

#~ sub _compiler_file {
  #~ my ($self, $topic) = @_;
    #~ diag "_compiler [%s]", $tmp;
  #~ my $mt = Mojo::Template->new;
#~ }
 
1;

=pod

=encoding utf8

Доброго всем

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::AssetPack::Pipe::VueTemplateCompiler - if you like separate files vue template and vue scrtipt.


=head1 SYNOPSIS

  $app->plugin('AssetPack::Che' => {
          pipes => [qw(VueTemplateCompiler CombineFile)],
          VueTemplateCompiler=>{enabled=>$ENV{MOJO_ASSETPACK_VUE_TEMPLATE_COMPILER} || 0},# pipe options
          process => [
            ['js/dist/templates/app★.js?bla'=>qw(components/foo.vue.html components/bar.vue.html)],
            ['app.js'=>qw('js/dist/templates/app★.js components/foo.vue.js components/bar.vue.js)],
            ...,
          ],
        });


=head1 Конфигурация CONFIG

Обработка файлов-шаблонов B<< \<path|url>.vue.html >> пойдет только (ONLY) в режиме development.

Обработанные топики шаблонов сохраняются в пути этого топика относительно static L<https://metacpan.org/pod/Mojolicious#static>.

В режиме production эти топики используются как обычные ассеты.


=head1 SEE ALSO

L<Mojolicious::Plugin::AssetPack::Che>

L<Mojolicious::Plugin::AssetPack>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-AssetPack-Che/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2020-2021 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__
@@ vue-template-compiler.js
#!/usr/bin/env node
"use strict"

let fs = require("fs");
let stdinBuffer = fs.readFileSync(0); // STDIN_FILENO = 0

const compiler = require('vue-template-compiler');
const util = require('@vue/component-compiler-utils');

///et c = compiler.compile(stdinBuffer.toString());

///let errs = c.errors;

//if (errs && errs.length) 
///  console.error(errs);


///delete c.ast;
///delete c.errors;

//console.log(c);
//process.stdout.write(JSON.stringify(c));
///process.stdout.write(c.render);

/***
  https://github.com/vuejs/component-compiler-utils#api
***/

let parse = util.parse({
  source: stdinBuffer.toString(),
  //~ filename?: string
  compiler,
  needMap: false,
});


let template = util.compileTemplate({
  source: parse.template.content,
  //~ filename: 
  compiler,
  isProduction: true,
  //~ transformAssetUrls: false,////susama
  //~ prettify:false,
  //~ isFunctional:true,
  //~ compilerOptions: {
    //~ scopeId
  //~ },
});

if (Array.isArray(template.errors) && template.errors.length >= 1) {
  //~ throw new Error(template.errors[0]);
  console.error(template.errors);
}
      
process.stdout.write(template.code);


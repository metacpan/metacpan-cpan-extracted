#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Apache::Build - Build your WebApp Package

=head1 DESCRIPTION

With this module you can prepare your WebApp for deployment.

=head1 SYNOPSIS

 yui_path "./yuicompressor-2.4.6.jar";

 get_version_from "webapp/lib/MyApp.pm", qr{\$VERSION=([^;]+);};

 get_version_from "webapp/index.php", qr{\$VERSION=([^;]+);};

 task "build", sub {
   sprocketize;
   sprocketize "app/assets/javascript/*.js",
    out => "public/js/sprockets.js";

   coffee;
   coffee "app/assets/coffee",
    out => "public/js";

   sass;
   sass "app/assets/stylesheets",
    out => "public/stylesheets";

   yui;
   yui compress => "file1.js", "file2.js", "file3.css";
   yui compress => glob("public/javascript/*.js"), glob("public/css/*.css");

   build;

   build "webapp",
    source  => "webapp/",
    version => "1.0";
 };


=head1 EXPORTED FUNCTIONS

=over 4

=cut

package Rex::Apache::Build;

our $VERSION = "0.12.0";

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Basename qw(basename);

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(build
  get_version_from get_version
  yui yui_path
  coffee coffee_path
  sprocketize sprocketize_path
  sass sass_path);

use vars qw($yui_path $coffee_path $sprocketize_path $sass_path $APP_VERSION);

use Rex::Commands::Run;
use Rex::Logger;

=item yui_path($path_to_yui_compressor)

This function sets the path to the yui_compressor. If a relative path is given it will search from the path where the Rexfile is in.

=cut

sub yui_path {
  ($yui_path) = @_;

  unless ( $yui_path =~ m/^\// ) {
    $yui_path = getcwd() . "/" . $yui_path;
  }
}

=item coffee_path($path_to_coffee)

This function sets the path to the coffee compiler. If a relative path is given it will search from the path where the Rexfile is in.

=cut

sub coffee_path {
  ($coffee_path) = @_;

  unless ( $coffee_path =~ m/^\// ) {
    $coffee_path = getcwd() . "/" . $coffee_path;
  }
}

=item sprocketize_path($path_to_sprocketize)

This function sets the path to the sprocketize compiler. If a relative path is given it will search from the path where the Rexfile is in.

=cut

sub sprocketize_path {
  ($sprocketize_path) = @_;

  unless ( $sprocketize_path =~ m/^\// ) {
    $sprocketize_path = getcwd() . "/" . $sprocketize_path;
  }
}

=item sass_path($path_to_sass)

This function sets the path to the sass compiler. If a relative path is given it will search from the path where the Rexfile is in.

=cut

sub sass_path {
  ($sass_path) = @_;

  unless ( $sass_path =~ m/^\// ) {
    $sass_path = getcwd() . "/" . $sass_path;
  }
}

=item yui($action, @files)

Run a yui command.

 task "build", sub {
   # this will compress the given files
   yui compress => "file1.js", "file2.js", ...;

   # yui without any parameters will compress all files in public/javascripts
   yui;
 };

=cut

sub yui {
  my ( $action, @data ) = @_;

  $yui_path ||= "yuicompressor.jar";

  unless ( -f $yui_path ) {
    die(
      "No yuicompressor.jar found. Please download this file and define its location with yui_path '/path/to/yuicompress.jar';"
    );
  }

  unless ($action) {
    $action = "compress";
  }

  unless (@data) {
    @data = glob("public/javascripts/*.js");
  }

  if ( $action eq "compress" || $action eq "-compress" ) {
    my @js_files  = grep { !/\.min\.js$/ } grep  { /\.js$/i } @data;
    my @css_files = grep { !/\.min\.css$/ } grep { /\.css$/i } @data;

    if (@js_files) {
      Rex::Logger::info("Compressing javascript files");
      for my $file (@js_files) {
        my $new_file = $file;
        $new_file =~ s/\.js$/.min.js/;
        Rex::Logger::debug("Compressing $file -> $new_file");
        run "java -jar $yui_path -o $new_file $file";
      }
    }

    if (@css_files) {
      Rex::Logger::info("Compressing css files");
      for my $file (@css_files) {
        my $new_file = $file;
        $new_file =~ s/\.css$/.min.css/;
        Rex::Logger::debug("Compressing $file -> $new_file");
        run "java -jar $yui_path -o $new_file $file";
      }
    }
  }
  else {
    die("Action $action not supported.");
  }
}

=item build([$name, %options])

This function builds your package. Currently only tar.gz packages are supported.

 # this will a package of the current directory named after the
 # directory of the Rexfile and append the version provided by
 # get_version_from() function
 # This function builds a tar.gz archive.
 task "build", sub {
   build;
 };

 # this will build a package of the current directory named "my-web-app" and
 # append the version provided by get_version_from() function.
 task "build", sub {
   build "my-web-app";
 };

 # this function will build a package of the directory "html", name it
 # "my-web-app" and append the version "1.0" to it.
 task "build", sub {
   build "my-web-app",
     path => "html",
     version => "1.0",
     exclude => ["yuicompressor.jar", "foobar.html"],
     type => "tgz";
 };

=cut

sub build {
  my ( $name, %option ) = @_;

  unless ($name) {
    $name = basename( getcwd() );
  }

  if ( !%option ) {
    if ( Rex::Config->get("package_option") ) {
      %option = %{ Rex::Config->get("package_option") };
    }
  }

  if ( !exists $option{version} ) {
    $option{version} = &$APP_VERSION();
  }

  my $old_dir = getcwd();

  my $type = $option{type} || "tgz";

  my $klass = "Rex::Apache::Build::$type";
  eval "use $klass";
  if ($@) {
    die("Can't find build class for type: $type");
  }

  Rex::Logger::debug("Using Buildclass: $klass");
  $option{name} = $name;
  my $build = $klass->new(%option);

  $build->build;

  chdir($old_dir);
}

=item get_version_from($file, $regexp)

Get the version out of a file.

=cut

sub get_version_from {
  my ( $file, $regex ) = @_;

  if ( ref($file) eq "CODE" ) {
    $APP_VERSION = $file;
    return;
  }

  $APP_VERSION = sub {

    unless ( -f $file ) {
      Rex::Logger::info( "Version file not found ($file). Current Path: "
          . getcwd()
          . ". Using current time." );
      return "" . time;
    }

    my ($version) =
      grep { $_ = $1 if $_ =~ $regex; } eval { local (@ARGV) = ($file); <>; };

    return $version;

  };
}

sub get_version {
  return &$APP_VERSION();
}

=item sprocketize($path_to_js_files, %option)

This function calls the sprocketize command with the given options.

 task "build", sub {
   sprocketize "app/javascript/*.js",
            include   => [qw|app/javascripts vendor/sprockets/prototype/src|],
            asset_root => "public/js",
            out      => "public/js/sprockets.js";

   # to include more use an arrayRef
   sprocketize ["app/javascript/*.js", "app/javascript/po/*.js"],
            include   => [qw|app/javascripts vendor/sprockets/prototype/src|],
            asset_root => "public/js",
            out      => "public/js/sprockets.js";

   # if called without parameters

   sprocketize;

   # it will use the following defaults:
   # - javascript (sprockets) in assets/javascripts/*.js
   # - include  assets/javascripts
   # - asset_root public
   # - out public/${name_of_directory_where_Rexfile_lives}.js
 };

=cut

sub sprocketize {
  my ( $files, %option ) = @_;

  my $dirname = basename( getcwd() );

  unless ($sprocketize_path) {
    $sprocketize_path = "sprocketize";
  }

  unless ($files) {
    $files = ["assets/javascripts/*.js"];
  }

  if ( !exists $option{out} ) {
    $option{out} = "public/$dirname.js";
  }

  if ( !exists $option{asset_root} ) {
    $option{asset_root} = "public";
  }

  if ( !exists $option{include} ) {
    $option{include} = ["app/javascripts"];
  }

  if ( ref($files) ne "ARRAY" ) {
    $files = [$files];
  }

  my $files_str = join( " ", @{$files} );
  my $includes = " -I " . join( " -I ", @{ $option{include} } );

  Rex::Logger::info("Sprocketizing...");
  run "$sprocketize_path $includes --asset-root="
    . $option{asset_root}
    . " $files_str > "
    . $option{out};
  if ( $? == 0 ) {
    Rex::Logger::info("...done.");
  }
  else {
    Rex::Logger::info("Error running sprocketize");
    die("Error running sprocketize");
  }
}

=item coffee($path, %options)

Compile coffee files to javascript.

 task "build", sub {
   # this command will build all files in "coffeesrc" and
   # write the output to "javascripts"
   coffee "coffeesrc",
      out  => "javascripts";

   # without parameters it will build all files in assets/coffee
   # and write the output to public/javascripts.
   coffee;
 };

=cut

sub coffee {
  my ( $path, %option ) = @_;

  unless ($coffee_path) {
    $coffee_path = "coffee";
  }

  unless ($path) {
    $path = "assets/coffee";
  }

  if ( !exists $option{out} ) {
    $option{out} = "public/javascripts";
  }

  Rex::Logger::info("Building coffee script files...");
  my $ret = run "coffee -o " . $option{out} . " -c " . $path . " 2>&1";

  if ( $? == 0 ) {
    Rex::Logger::info("...done.");
  }
  else {
    Rex::Logger::info("Error building coffeescripts. $ret");
    die("Error building coffeescripts.");
  }
}

=item sass($input_dir, %option)

This command will compile all sass files in $input_dir.

 task "build", sub {
   # this command will compile all sass files from app/assets/stylesheets
   # and put the output into public/stylesheets.
   sass "app/assets/stylesheets",
    out => "public/stylesheets";

   # The default is to build all files in assets/sass and put the output
   # into public/css.
   sass;
 };

=cut

sub sass {
  my ( $input, %option ) = @_;

  unless ($sass_path) {
    $sass_path = "sass";
  }

  unless ($input) {
    $input = "assets/sass";
  }

  if ( !exists $option{out} ) {
    $option{out} = "public/css";
  }

  Rex::Logger::info("Building sass files...");
  my $ret = run "$sass_path -q --update $input:" . $option{out} . " 2>&1";

  if ( $? == 0 ) {
    Rex::Logger::info("...done.");
  }
  else {
    Rex::Logger::info("Failed building sass files. $ret");
    die("Failed building sass files.");
  }
}

=back

=cut

1;

#!perl -w
#
# Last saved: Tue 31 Jan 2017 12:00:26 PM
#
#
use strict;

=head1 PURPOSE

This script extracts the function signatures from glew-2.0.0/include/GL/glew.h
and creates XS stubs for each.

This should also autogenerate stub documentation by adding links
to the OpenGL documentation for each function via

L<https://www.opengl.org/sdk/docs/man/html/glShaderSource.xhtml>

Also, it should parse the feature groups of OpenGL and generate a data structure
that shows which features are associated with which functions.

=cut

my @headers = glob "include/GL/*.h";

my %signature;
my %case_map;
my %alias;

# The functions where we specify manual implementations or prototypes
# These could also be read from Modern.xs, later maybe
my @manual_list = qw(
  glGetString
  glShaderSource_p
);

my %manual;
@manual{@manual_list} = ( 1 ) x @manual_list;

my @exported_functions;    # here we'll collect the names the module exports

push @exported_functions, $_ foreach @manual_list;

# TODO: check against the typedefs in glew.h.  All the simple GL types have names
# matching GL\w+ and don't match the glew typedefs to define the OpenGL API bindings.
# The callback typedefs match qr/(\w+) callback\b/ and the call back signature is
# in another typedef matching the callback typedef spec.  The final addition is
# for void which is a standard type so the spec for the API folks didnt' think it
# needed to be wrapped.
#
my @known_type = sort { $b cmp $a } qw(
  GLbitfield
  GLboolean
  GLbyte
  GLchar
  GLcharARB
  GLclampd
  GLclampf
  GLclampx
  GLdouble
  GLenum
  GLfixed
  GLfloat
  GLhalf
  GLhandleARB
  GLint
  GLint64
  GLint64EXT
  GLintptr
  GLintptrARB
  GLuint
  GLuint64
  GLuint64EXT
  GLshort
  GLsizei
  GLsizeiptr
  GLsizeiptrARB
  GLsync
  GLubyte
  GLushort
  GLvdpauSurfaceNV
  GLvoid
  void

  cl_context
  cl_event

  GLLOGPROCREGAL
  GLDEBUGPROCARB
  GLDEBUGPROCAMD
  GLDEBUGPROC
);

# Functions where we need to override the type signature
# The keys are API function names and the values are hash
# refs giving the name of the argument to modify and the
# new type to use instead.
#
# NOTE: The current implementation appears to handle only
# one name/type override per API function and is undocumented
# except looking at the code.
my %signature_override = ( 'glFunctionName' => { name => 'parameter name', type => 'new parameter type' }, );

my %features = ();

for my $file ( @headers ) {

    my $feature_name;

    print "Processing file $file\n";

    open my $fh, '<', $file
      or die "Couldn't read '$file': $!";

    while ( my $line = <$fh> ) {
        if ( $line =~ m|^#define (\w+) 1\r?$| and $1 ne 'GL_ONE' and $1 ne 'GL_TRUE' ) {
            $feature_name = $1;

            # #endif /* GL_FEATURE_NAME */
        }
        elsif ( defined( $feature_name ) and $line =~ m|^#endif /* $feature_name */$| ) {

            # End of lines for this OpenGL feature
            $feature_name = undef;

            # typedef void* (GLAPIENTRY * PFNGLMAPBUFFERPROC) (GLenum target, GLenum access);
            # typedef void (GLAPIENTRY * PFNGLGETQUERYIVPROC) (GLenum target, GLenum pname, GLint* params);
        }
        elsif ( $line =~ m|^typedef (\w+(?:\s*\*)?) \(GLAPIENTRY \* PFN(\w+)PROC\)\s*\((.*)\);| ) {
            my ( $restype, $name, $sig ) = ( $1, $2, $3 );
            my $s =
              { signature => $sig, restype => $restype, feature => $feature_name, name => $name, glewtype => 'fun' };
            $signature{$name} = $s;
            push @{ $features{$feature_name} }, $s;

            # GLAPI void GLAPIENTRY glClearColor (GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
        }
        elsif ( $line =~ m|^GLAPI ([\w* ]+?) GLAPIENTRY (\w+) \((.*)\);| ) {

            # Some external function, likely imported from libopengl / opengl32
            my ( $restype, $name, $sig ) = ( $1, $2, $3 );
            my $s =
              { signature => $sig, restype => $restype, feature => $feature_name, name => $name, glewtype => 'fun' };
            $signature{ uc $name } = $s;
            $case_map{ uc $name }  = $name;
            push @{ $features{$feature_name} }, $s;

            # GLEW_FUN_EXPORT PFNGLACTIVETEXTUREPROC __glewActiveTexture;
        }
        elsif ( $line =~ m|^GLEW_FUN_EXPORT PFN(\w+)PROC __(\w+)| ) {
            my ( $name, $impl ) = ( $1, $2 );
            $case_map{$name} = $impl;

            # #define glCopyTexSubImage3D GLEW_GET_FUN(__glewCopyTexSubImage3D)
        }
        elsif ( $line =~ m|^#define (\w+) GLEW_GET_FUN\(__(\w+)\)| ) {
            my ( $name, $impl ) = ( $1, $2 );
            $alias{$impl} = $name;

            # #define GLEW_VERSION_1_1 GLEW_GET_VAR(__GLEW_VERSION_1_1)
        }
        elsif ( $line =~ m|^#define (\w+) GLEW_GET_VAR\(__(\w+)\)| ) {
            my ( $name, $impl ) = ( $1, $2 );
            $alias{$impl} = $name;

            # GLEW_VAR_EXPORT GLboolean __GLEW_VERSION_1_1;
        }
        elsif ( $line =~ m|^GLEW_VAR_EXPORT (\w+) __(\w+)| ) {
            my ( $restype, $impl ) = ( $1, $2 );
            my $s = { signature => 'void', restype => $restype, feature => $feature_name, glewtype => 'var' };
            my $name = $alias{$impl};
            $signature{$name} = $s;
            push @{ $features{$feature_name} }, $s;
            $case_map{$name} = $impl;

        }
    }
}

# Now rewrite the names to proper case when we only have their uppercase alias
for my $name ( sort keys %signature ) {
    my $impl      = $case_map{$name} || $name;
    my $real_name = $alias{$impl}    || $impl;

    my $s = $signature{$name};
    $s->{name} = $real_name;
}

# use Data::Dump qw(pp);
# pp(values %signature);

=head1 Automagic Perlification

We should think about how to ideally enable the typemap
to automatically perlify the API. Or just handwrite
it for the _p functions?!

We should move the function existence check
into the AUTOLOAD part so the check is made only once
instead of on every call. Microoptimization, I know.

=cut

sub munge_GL_args {
    my ( @args ) = @_;

    # GLsizei n
    # GLsizei count
}

sub generate_glew_xs {
    my ( @items ) = @_;
    my @process = map { uc $_ } @items;
    if ( !@process ) {
        @process = sort keys %signature;
    }

    my $content;

    for my $upper ( @process ) {
        my $item = $signature{$upper};

        my $name = $item->{name};

        if ( $manual{$name} ) {
            print "Skipping $name, already implemented in Modern.xs\n";
            next;
        }

        my $args = $item->{signature};    # XXX clean up the C arguments here
        die "No args for $upper" unless $args;
        my $type = $item->{restype};      # XXX clean up the C arguments here
        my $no_return_value;

        # Track number of pointer type args/return values (either * or [])
        my $num_ptr_types = 0;

        if ( $type eq 'void' ) {
            $no_return_value = 1;
        }

        $num_ptr_types += ( $type =~ tr/*[/*[/ );

        my $glewImpl;
        if ( $item->{feature} ne "GL_VERSION_1_1" ) {
            ( $glewImpl = $name ) =~ s!^gl!__glew!;
        }

        my $xs_args = $item->{signature};
        if ( $args eq 'void' ) {
            $args    = '';
            $xs_args = '';
        }

        $num_ptr_types += ( $args =~ tr/*[/*[/ );

        # rewrite GLsync GLsync into GLsync myGLsync:
        for ( $args, $xs_args ) {
            s!\bGLsync(\s+)GLsync!GLsync$1myGLsync!g;
        }

        my @xs_args = split /,/, $xs_args;

        # Patch function signatures if we want other types
        if ( my $sig = $signature_override{$name} ) {
            for my $arg ( @xs_args ) {
                my $name = $sig->{name};
                my $type = $sig->{type};
                if ( $arg =~ /\b\Q$name\E\r?$/ ) {
                    $arg = "$type $name";
                }
            }
        }

        $xs_args = join ";\n    ", @xs_args;

        # Rewrite const GLwhatever foo[];
        # into    const GLwhatever* foo;
        1 while $xs_args =~ s!^\s*const (\w+)\s+(\w+)\[\d*\](;?)\r?$!     const $1 * $2$3!m;
        1 while $xs_args =~ s!^\s*(\w+)\s+(\w+)\[\d*\](;?)\r?$!     $1 * $2$3!m;

        # Meh. We'll need a "proper" C type parser here and hope that we don't
        # incur any macros
        my $known_types = join "|", @known_type;
        $args =~ s!\b(?:(?:const\s+)?\w+(?:(?:\s*(?:\bconst\b|\*)))*\s*(\w+))\b!$1!g;

        1 while $args =~ s!(\bconst\b|\*|\[\d*\])!!g;

        # Kill off all pointer indicators
        $args =~ s!\*! !g;

        # Determine any name suffixes
        # All routines with * or [] in the return value or arguments
        # have a '_c' suffix variant.
        my $binding_name = ( $num_ptr_types > 0 ) ? $name . '_c' : $name;

        push @exported_functions, $binding_name;

        my $decl = <<XS;
$type
$binding_name($args);
XS
        if ( $xs_args ) {
            $decl .= "     $xs_args;\n";
        }

        my $res = $decl . <<XS;
CODE:
    if ( ! _done_glewInit ) {
        glewExperimental = GL_TRUE;
        glewInit() || _done_glewInit++;
    }
XS
        if ( $item->{glewtype} eq 'fun' and $glewImpl ) {
            $res .= <<XS;
    if ( ! $glewImpl ) {
        croak("$name not available on this machine");
    };
XS
        }

        if ( $no_return_value ) {
            $res .= <<XS;
    $name($args);

XS

        }
        else {
            $res .= "    RETVAL = $name" . ( ( $item->{glewtype} eq 'var' ) ? ";\n" : "($args);\n" );
            $res .= <<XS;
OUTPUT:
    RETVAL

XS
        }

        $content .= $res;
    }
    return $content;
}

sub slurp {
    my $filename = $_[0];
    open my $old_fh, '<:raw', $filename
      or die "Couldn't read '$filename': $!";
    join '', <$old_fh>;
}

sub save_file {
    my ( $filename, $new ) = @_;
    my $old = -e $filename ? slurp( $filename ) : "";
    if ( $new ne $old ) {
        print "Saving new version of $filename";
        open my $fh, '>:raw', $filename
          or die "Couldn't write new version of '$filename': $!";
        print $fh $new;
    }
}

my $xs_code = generate_glew_xs( @ARGV );
save_file( 'auto-xs.inc', $xs_code );

# Now rewrite OpenGL::Modern.pm if we need to:
if ( !@ARGV ) {
    my $glFunctions = join "\n      ", @exported_functions;

    my %glGroups = map {
        $_ => [ map { $_->{name} } @{ $features{$_} } ],
    } sort keys %features;
    use Data::Dumper;
    $Data::Dumper::Sortkeys = 1;
    my $gltags = Dumper \%glGroups;
    $gltags =~ s!\$VAR1 = \{!!;
    $gltags =~ s!\s+};$!!;

    my $new = <<"END";
package OpenGL::Modern::NameLists::Modern;

# ATTENTION: This file is automatically generated by utils/generate-XS.pl!
#            Manual changes will be lost.

sub gl_functions {
    qw(
      $glFunctions
    );
}

sub EXPORT_TAGS_GL {
    ($gltags    );
}

1;
END

    save_file( "lib/OpenGL/Modern/NameLists/Modern.pm", $new );
}

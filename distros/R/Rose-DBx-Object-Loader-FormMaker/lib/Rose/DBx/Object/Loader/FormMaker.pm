package Rose::DBx::Object::Loader::FormMaker;

use strict;

use Rose::DB::Object::Loader;
use Carp;
use Cwd;
use File::Path;
use File::Spec;
use Rose::Object::MakeMethods::Generic (
  scalar => ['base_tabindex']
);
our $VERSION = '0.03';

BEGIN { our @ISA = qw(Rose::DB::Object::Loader) }

=head1 NAME

Rose::DBx::Object::Loader::FormMaker - Automatically create RHTMLO Forms with the RDBO Loader

=head1 SYNOPSIS

hi there

=head2 B<make_modules [PARAMS]>

see the documentation for Rose::DB::Object::Loader for the bulk of the 
configuration options for make_modules. FormMaker adds a couple of options
to what Loader provides described below:

=over 4

=item B<form_prefix [PREFIX]>

The prefix used for Form classes created by FormMaker.  Basically the same thing
as class_prefix provided by loader.  It must not be the same as class_prefix or
Bad Things will happen.

=item B<form_base_classes [ CLASS | ARRAYREF ]>

The same as base_classes, but for Forms. Defaults to 'Rose::HTML::Form'.

=item B<base_tabindex [ SCALAR ]>

The lowest tabindex that should be used for form elements in the created forms.
Defaults to 1.

=back

=cut

sub make_modules {
    my ($self,%args) = @_;

    my @classes = $self->SUPER::make_modules(%args);

    my $module_dir = exists $args{'module_dir'} ? 
        delete $args{'module_dir'} : $self->module_dir;

    $module_dir = cwd()  unless(defined $module_dir);
    
    my @form_classes;
    foreach my $class (@classes) {

        next unless ($class->isa('Rose::DB::Object'));

        my $class_name = scalar $class;
	my $class_prefix = $self->class_prefix;
	my $form_prefix = $self->form_prefix;

	$class_name =~ s|$class_prefix|$form_prefix|;
	push @form_classes, $class_name;

        my @path = split('::', $class_name);
        $path[-1] .= '.pm';
        unshift(@path, $module_dir);

        my $dir = File::Spec->catfile(@path[0 .. ($#path - 1)]);

        mkpath($dir)  unless(-e $dir);

        unless(-d $dir) {
            if(-f $dir) {
                croak "Could not create module directory '$module_dir' - a file ",
                      "with the same name already exists";
            }
            croak "Could not create module directory '$module_dir' - $!";
        }

        my $file = File::Spec->catfile(@path);

        open(my $pm, '>', $file) or croak "Could not create $file - $!";

        my $preamble = exists $args{'module_preamble'} ? 
            $args{'module_preamble'} : $self->module_preamble;

        my $postamble = exists $args{'module_postamble'} ? 
            $args{'module_postamble'} : $self->module_postamble;

        if ($class->isa('Rose::DB::Object')) {
            if($preamble) {
                my $this_preamble = ref $preamble eq 'CODE' ? 
                    $preamble->($class->meta) : $preamble;

                print {$pm} $this_preamble;
            }

            print {$pm} $self->class_to_form($class);

            if($postamble) {
                my $this_postamble = ref $postamble eq 'CODE' ? 
                    $postamble->($class->meta) : $postamble;

                print {$pm} $this_postamble;
            }
        }
    }
    push @classes, @form_classes;

    return wantarray ? @classes : \@classes; 
}

=head2 class_to_form

=over 4

class_to_form takes an RDBO class, and using it's meta information 
constructs an RHTMLO Form object.

=back

=cut

sub class_to_form {
    my ($self, $class) = @_;
    my $class_name = scalar $class;
    my $class_prefix = $self->class_prefix;
    my $form_prefix = $self->form_prefix;
    $class_name =~ s|$class_prefix|$form_prefix|;
    
    my $code;

    my $base_classes = $self->form_base_classes;
    my $uses;
    my $isa;
    foreach my $class (@$base_classes) {
        $uses .= $uses ? qq[\n] . qq[use $class;] : qq[use $class;];
	$isa .= $isa ? qq[ ]. $class : $class;
    }

    $code .=qq[package $class_name;

use strict;
use warnings;

$uses
our \@ISA = qw($isa);

sub build_form {
    my(\$self) = shift;

    \$self->add_fields (
];
    my $count = $self->base_tabindex || 1;
    foreach my $column (sort __by_rank $class->meta->columns){
        #print STDERR $column.qq[ ] . $column->type .qq[\n];
        #$code .= $column.qq[\n];
	my $column_name = scalar $column;
        $code .= qq[
        $column_name => {
            id => '$column_name',
	    type => '].$column->type.qq[',
            label => '$column_name',
	    tabindex => $count,
        },];
        $count++;
    }
    $code .= qq[
    );
}

1;
];
    
    return $code;
}

=head2 form_prefix

form_prefix is just for the initialization of the form_prefix option to FormMaker

=cut

sub form_prefix {
    my($self) = shift;

    return $self->{'form_prefix'}  unless(@_);

    my $form_prefix = shift;

    if (length $form_prefix) {
        unless($form_prefix =~ /^(?:\w+::)*\w+(?:::)?$/) {
            croak "Illegal class prefix: $form_prefix";
        }
        $form_prefix .= '::'  unless($form_prefix =~ /::$/);
    }

    return $self->{'form_prefix'} = $form_prefix;
}

#
# ripped from loader to sort columns
#
sub __by_rank {  
  my $pos1 = $a->ordinal_position;
  my $pos2 = $b->ordinal_position;

  if(defined $pos1 && defined $pos2)
  {
    return $pos1 <=> $pos2 || lc($a->name) cmp lc($b->name);
  }

  return lc($a->name) cmp lc($b->name);
}

=head2 form_base_classes

get/set the base class(es) for the Form objects

=cut
sub form_base_classes {
    my $self = shift;

    unless (@_) {
        if (my $bc = $self->{'form_base_classes'}) {
            return wantarray ? @$bc : $bc;
	}
	my $bc = [qq[Rose::HTML::Form]];
	
	return wantarray ? @$bc : $bc;
    }
    
    my $bc = shift;

    unless (ref($bc)) {
        $bc = [ $bc ];
    }
    
    $self->{'form_base_classes'} = $bc;
    return wantarray ? @$bc : $bc;

}

1;

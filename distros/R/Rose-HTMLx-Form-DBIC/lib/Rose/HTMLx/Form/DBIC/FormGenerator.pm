package Rose::HTMLx::Form::DBIC::FormGenerator;

use strict;
use warnings;
use Moose;
use DBIx::Class;
use Template;
use version; our $VERSION = qv('0.0.3');

has 'schema' => (
    is  => 'rw',
    isa => 'DBIx::Class::Schema',
);

has 'tt' => (
    is => 'ro',
    default => sub { Template->new() },
);

has 'class_prefix' => (
    is => 'ro',
);

has 'style' => (
    is => 'ro'
);

has 'm2m' => (
    is => 'ro'
);

my $form_template = <<'END';
[% FOR form = forms %]
{
    package [% form.class %]Form;
    use base "Rose::HTML::Form";
    
    sub build_form {
        my($self) = shift;
        $self->method( 'POST' );
    
        $self->add_fields (
    [% FOR field = form.fields -%]
    [%- SET field_name = field.name; field.delete( 'name' ); -%]
            [% field_name %] => { [% FOREACH attr IN field.pairs %] [% attr.key %] => '[% attr.value %]', [% END %] },
    [% END %]
        );
        $self->add_forms ( 
    [% FOR sub_form = form.sub_forms -%]
[% IF single %]#[% END %]            [% sub_form.name %] => [% sub_form.class %]Form->new,
    [% END %]
        );
    
        
    }

}
[% END %]

END

sub generate_form {
    my ( $self, $rsname ) = @_;
    my $config = $self->get_config( $rsname );
    my $output;
    my %sub_forms = map { $_->{class} => $_ } @{$config->{sub_forms}};
    my $tmpl_params = {
        forms => [ $config, values %sub_forms ], 
    };
    $tmpl_params->{single} = 1 if defined $self->style && $self->style eq 'single';
    $self->tt->process( \$form_template, $tmpl_params, \$output )
                   || die $self->tt->error(), "\n";
    return $output;
}

sub _strip_class {
    my $fullclass = shift;
    my @parts     = split /::/, $fullclass;
    my $class     = pop @parts;
    return $class;
}

sub get_config {
    my( $self, $class ) = @_;
    my $config = $self->get_elements ( $class, 0, );
    push @{$config->{fields}}, {
        type => 'submit',
        name => 'foo',
    };
    my $target_class = $class;
    $target_class = $self->class_prefix . '::' . $class if $self->class_prefix;
    $config->{class} = $target_class;
    return $config;
}

my %types = (
    text      => 'textarea',
    'int'     => 'int',
    integer   => 'integer',
    num       => 'num',
    number    => 'number',
    numeric   => 'numeric',
);
    
   
sub m2m_for_class {
    my( $self, $class ) = @_;
    return if not $self->m2m;
    return if not $self->m2m->{$class};
    return @{$self->m2m->{$class}};
}

sub get_elements {
    my( $self, $class, $level, @exclude ) = @_;
    my $source = $self->schema->source( $class );
    my %primary_columns = map {$_ => 1} $source->primary_columns;
    my @fields;
    my @sub_forms;
    my @fieldsets;
    for my $rel( $source->relationships ) {
        next if grep { $_ eq $rel } @exclude;
        next if grep { $_->[1] eq $rel } $self->m2m_for_class($class);
        my $info = $source->relationship_info($rel);
        my @self_cols = get_self_cols( $info->{cond} );
        push @exclude, @self_cols;
        my $rel_class = _strip_class( $info->{class} );
        my $elem_conf;
        if ( ! ( $info->{attrs}{accessor} eq 'multi' ) ) {
            my $new_element = { 
                name => $rel, 
                type => 'selectbox' 
            };
            my $col_info = $source->column_info($self_cols[0]);
            $new_element->{required} = 1 if not $col_info->{is_nullable};
            push @fields, $new_element;
        }
        elsif( $level < 1 ) {
            my @new_exclude = get_foreign_cols ( $info->{cond} );
            my $config = $self->get_elements ( $rel_class, 1, );
            my $target_class = $rel_class;
            $target_class = $self->class_prefix . '::' . $rel_class if $self->class_prefix;
            $config->{class} = $target_class;
            $config->{name} = $rel;
            push @sub_forms, $config;
        }
    }
    for my $col ( $source->columns ) {
        my $new_element = { name => $col };
        my $info = $source->column_info($col);
        if( $primary_columns{$col} ){ 
            # - generated schemas have not is_auto_increment set so
            # so the below needs to be commented out
            # and $info->{is_auto_increment} ){  
            $new_element->{type} = 'hidden';
        }   
        else{
            next if grep { $_ eq $col } @exclude;
            my $type = $types{ $info->{data_type} } || 'text'; 
            $type = 'textarea' if defined($info->{size}) && $info->{size} > 60;
            $new_element->{type}  = $type;
            $new_element->{size}  = $info->{size} if $type eq 'text';
            $new_element->{required} = 1 if not $info->{is_nullable};
        }
        unshift @fields, $new_element;
    }
    for my $many( $self->m2m_for_class($class) ){
        unshift @fields, { 
            name => $many->[0], 
            type => 'select', 
            multiple => 1 
        };
    }
    return { fields => \@fields, sub_forms => \@sub_forms };
}

sub get_foreign_cols{
    my $cond = shift;
    my @cols;
    if ( ref $cond eq 'ARRAY' ){
        for my $c1 ( @$cond ){
            push @cols, get_foreign_cols( $c1 );
        }
    }
    elsif ( ref $cond eq 'HASH' ){ 
        for my $key ( keys %{$cond} ){
            if( $key =~ /foreign\.(.*)/ ){
                push @cols, $1;
            }
        }
    }
    return @cols;
}

sub get_self_cols{
    my $cond = shift;
    my @cols;
    if ( ref $cond eq 'ARRAY' ){
        for my $c1 ( @$cond ){
            push @cols, get_self_cols( $c1 );
        }
    }
    elsif ( ref $cond eq 'HASH' ){ 
        for my $key ( values %{$cond} ){
            if( $key =~ /self\.(.*)/ ){
                push @cols, $1;
            }
        }
    }
    return @cols;
}


#################### main pod documentation begin ###################
## Below is the stub of documentation for your module. 
## You better edit it!


=head1 NAME

Rose::HTMLx::Form::DBIC::FormGenerator - generates Rose::HTML forms from database schema

=head1 SYNOPSIS

  use Rose::HTMLx::Form::DBIC::FormGenerator;
  my $generator = Rose::HTMLx::Form::DBIC::FormGenerator->new( schema => $schema );
  my $output = $generator->generate_form( 'User' );


=head1 DESCRIPTION


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Zbigniew Lukasiak
    CPAN ID: zby
    http://perlalchemy.blogspot.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value




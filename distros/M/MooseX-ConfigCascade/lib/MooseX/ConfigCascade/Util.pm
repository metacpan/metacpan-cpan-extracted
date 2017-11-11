package MooseX::ConfigCascade::Util;

use Moose;
use MooseX::ClassAttribute;
use Carp;
use Module::Runtime qw(require_module);

class_has conf => (is => 'rw', isa => 'HashRef', lazy => 1, default => sub{
    $_[0]->parser->($_[0]->path);
});

class_has path => (is => 'rw', isa => 'Str', trigger => sub{
    $_[0]->conf( $_[0]->parser->($_[0]->path) )
});

class_has parser => (is => 'rw', isa => 'CodeRef', lazy => 1, default => sub{sub{
    return {} unless $_[0];
    open my $fh,'<',$_[0] or confess "Could not open file ".$_[0].": $!";
    my $file_text = '';
    while( my $row = <$fh> ){ $file_text.=$row }
    if ( $file_text =~ /^\s*\{/s ){
        require_module('JSON');
        return JSON::decode_json( $file_text )
    } elsif ( $file_text =~ /^\s*\-/s ){
        require_module('YAML');
        return YAML::Load($file_text);
    }
    confess "Error reading $_: Could not understand file format";
}});


has _stack => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub{[]});
has _to_set => (is => 'ro', isa => 'Object'); # $self for the object that has the MooseX::ConfigCascade role
has _role_name => (is => 'ro', isa => 'Str'); # 'MooseX::ConfigCascade' unless the name changes
has _att_name => (is => 'rw', isa => 'Str'); # the name of the attribute in the parent that has this object
has _args => (is => 'rw', isa => 'HashRef', default => sub{{}}); #original arguments passed to the constructor



sub _parse_atts{
    my $self = shift;

    $self->_set_atts( $self->conf );
    while( my $conf_h = pop @{$self->_stack} ){
        $self->_set_atts( $conf_h );
    }
}


sub _get_att_list{
    my ($self,$conf_h) = @_;

    my $att_list = [];

    if ( ! $self->_att_name && $conf_h->{ref($self->_to_set)} ){
        push @$att_list, $conf_h->{ref($self->_to_set)};        
    } elsif ( $self->_att_name && $conf_h->{ $self->_att_name } ){
        push @$att_list, $conf_h->{ $self->_att_name };
    }
    return $att_list;    
}

                        
sub _set_atts{
    my ($self, $conf_h ) = @_;

    my $to_set = $self->_to_set;
    my $att_list = $self->_get_att_list( $conf_h );
    
    foreach my $att_set (@$att_list){
        foreach my $att_name (keys %$att_set){
            if ($to_set->can( $att_name ) && ! defined $self->_args->{ $att_name }){
                
                my $att = $to_set->meta->find_attribute_by_name($att_name);
                my $tc = $att->type_constraint;
                
                if ($tc->is_a_type_of('Str') ||
                    $tc->is_a_type_of('HashRef') ||
                    $tc->is_a_type_of('ArrayRef') ||
                    $tc->is_a_type_of('Bool')){

                    $att->set_value($to_set,$att_set->{$att_name});

                } elsif ( 
                        $tc->is_a_type_of('Object')
                    &&  $to_set->$att_name->DOES( $self->_role_name )
                ){
                
                        my $util = $to_set->$att_name->cascade_util;
                        $util->_att_name( $att_name );
                        unshift @{$util->_stack}, $att_set;
                        $util->_parse_atts;
                }
            }
        }
    }
}

1;
__END__
=head1 NAME

MooseX::ConfigCascade::Util - utility module for L<MooseX::ConfigCascade>

=head1 SYNOPSIS

    use MooseX::ConfigCascade::Util;

    MooseX::ConfigCascade::Util->path(      # set the path to the config file

        '/path/to/config.json' 

    );  


    MooseX::ConfigCascade::Util->conf(      # set the config hash directly

        \%conf 

    ); 


    MooseX::ConfigCascade::Util->parser(    # set the sub that parses the 
                                            # config file
        $subroutine_reference

    );


=head1 DESCRIPTION

This is module is the workhorse of L<MooseX::ConfigCascade>. See the L<MooseX::ConfigCascade> documentation for a general overview of how to implement L<MooseX::ConfigCascade> in your project.

=head1 METHODS

MooseX provides an attribute C<conf> which stores a hash of config directives, and 2 attributes L<path> and L<parser> which control how L<conf> is loaded

=head2 conf

This is a hashref containing config information. See the documentation for L<MooseX::ConfigCascade> to learn how this should be structured. It can be set directly

    MooseX::ConfigCascade::Util->conf( \%conf );

Alternatively it is set indirectly when 'path' is changed

=head2 path

Call this to set the path to your config file. For more information about the format of your config file, see the documentation for L<MooseX::ConfigCascade>.

    MooseX::ConfigCascade::Util->path( '/path/to/my_config.json' );

When L<path> is changed it reads the specified file and overwrites L<conf> with the new values. Any new objects created after that will get the new values.

=head2 parser

This is the subroutine responsible for converting the file specified in path to a hashref. Setting this to a new value means you can use L<MooseX::ConfigCascade> with a config file of arbitrary format. But look at the expected format of this sub below, and use with caution:

Your parser subroutine should collect L<path> from the input arguments, do whatever is necessary to convert the file, and finally output the hashref which will be stored in L<conf>':

    my $parser = sub {
        my $path = shift;

        open my $fh, '<', $path or die "Could not open $path: $!";


        my %conf;

        # .... read the values into %conf


        return \%conf;
    }

=head1 SEE ALSO

L<MooseX::ConfigCascade::Util>
L<Moose>
L<MooseX::ClassAttribute>

=head1 AUTHOR

Tom Gracey E<lt>tomgracey@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Tom Gracey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

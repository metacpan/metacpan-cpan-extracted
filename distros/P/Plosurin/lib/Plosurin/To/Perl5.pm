#===============================================================================
#
#  DESCRIPTION:  Export to Perl 5
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
=head1 NAME

Plosurin::To::Perl5 - export to Perl 5 

=head1 SYNOPSIS

    my $p5  = new Plosurin::To::Perl5(
           'context' => $ctx,
           'writer'  => new Plosurin::Writer::Perl5,
           'package' => $package,
        );

  
=head1 DESCRIPTION

Plosurin::To::Perl5 - export to Perl 5

=cut
package Plosurin::To::Perl5;
use strict;
use warnings;
use v5.10;
use Data::Dumper;
use Plosurin::AbstractVisiter;
use base 'Plosurin::AbstractVisiter';

=head2 new context=>$ctx, writer=>$writer, package=>"Tmpl"


=cut

sub new {
    my $class = shift;
    my $self = bless( $#_ == 0 ? shift : {@_}, ref($class) || $class );
    $self->{nodeid} = 1;
    $self->{package} //= "Tmpl";
    $self;
}

=head2 writer or wr
Return current writer object. 
    $self->wr
    $self->writer
=cut

sub writer { $_[0]->{writer} }
sub wr     { $_[0]->{writer} }

=head2 context or ctx
 retrun current context
=cut

sub context { $_[0]->{context} }
sub ctx     { $_[0]->{context} }



sub start_write {
    my $self = shift;
    my $w    = $self->wr;
    return if $w->{start_write_done}++;
    $w->print(<<"TXT");
# Please don't edit this file by hand.
package $self->{package};
use strict;
use utf8;
=head1 NAME

$self->{package} - set of generated teplates 

=head1 SYNOPSIS

 use $self->{package};
 print &$self->{package}::some_template(key1=>val1);

=head1 DESCRIPTION

$self->{package} - set of generated teplates by plosurin

=cut

TXT

}

sub end_write {
    my $self = shift;
    $self->wr->print(<<TMPL);
1;
__END__

=head1 SEE ALSO

Closure Templates Documentation L<http://code.google.com/closure/templates/docs/overview.html>

Perl 6 implementation L<https://github.com/zag/plosurin>

=cut
TMPL
}

sub write {
    my $self   = shift;
    my $writer = $self->{writer};
    foreach my $n (@_) {
        $self->visit($n);
    }
}

#Node container of command. <content>
sub Node {
    my $self = shift;
    my $node = shift;
    $self->visit_childs($node);
}

sub command_call_self {
    my ( $self, $n ) = @_;
    return $self->command_call($n);
}

sub command_call {
    my ( $self, $n ) = @_;
    my $w        = $self->wr;
    my $ctx      = $self->ctx;
    my $template = $n->{tmpl_name};
    my $tmpl     = $ctx->get_template_by_name($template);
    my $sub = $ctx->get_perl5_name($tmpl) || die "Not found template $template";

    #if data='all' or empty params
    # &sub(@_)
    my $attr = $n->attrs;
    if ( scalar( @{ $n->childs } ) == 0
        || exists $attr->{data} && $attr->{data} eq 'all' )
    {

        $w->appendOutputVar( '&' . $sub . '(@_)' );
    }
    else {

        #if need external var ?
        #$self-> !!!!!  #TODO
        #if not
        my @params = ();
        foreach my $ch (
            map { UNIVERSAL::isa( $_, 'Soy::Node' ) ? @{ $_->childs } : $_ }
            @{ $n->childs } )
        {

            # skip not param nodes
            next unless UNIVERSAL::isa( $ch, 'Soy::command_param' );
            my $vname = 'param' . ++${ $w->{nodeid} };
            $w->pushOtputVar($vname);
            $self->visit($ch);
            push @params, { name => $ch->{name}, vname => $vname };
            $w->popOtputVar;
        }
        $w->say(qq!# calling template: $template;!);
        $w->appendOutputVar(
                '&' 
              . $sub . '('
              . join( ',',
                map { "'" . $$_{name} . q!' => $! . $$_{vname} } @params )
              . ')'
        );
    }
}

sub command_param {
    my ( $self, $node ) = @_;
    $self->visit_childs($node);
}

sub command_param_self {
    my ( $self, $node ) = @_;
    my $w = $self->wr;
    $w->appendOutputVar( $node->{value} );
}

sub raw_text {
    my ( $self, $node ) = @_;
    my $w = $self->wr;
    my $txt = $node->{''};
    #escape '
    $txt =~ s/'/\\'/g;
    $w->appendOutputVar("'$txt'");
}

=head2 File
Export File
=cut

sub File {
    my ( $self, $node ) = @_;
    my $w = $self->wr;

    #get tempales
    #    $self->visit_childs($node);
    #walk
    foreach my $t ( @{ $node->childs } ) {
        #setup current template
        #setup current params
        #make params map 
        my %params = ();
        foreach my $p ($t->params()) {
            $params{$p->name} = 0;
        }
        #setup current template PARAMS
        $self->{PARAMS} = \%params;
        
        my $tmpl_name = $t->name;
        my $namespace = $node->namespace;
        ( my $converted_name = $namespace . $tmpl_name ) =~ tr/\./_/;
        $w->print(<<TMPL);
=head1 $converted_name

@{[ $t->comment ]}

( I<src>: C<@{[ $node->{file} ]}>, I<template name>: C<$tmpl_name> )

=cut

sub $converted_name \{
    my %args = \@_;
TMPL
        $w->inc_ident;
        my $vname = 'param' . ++${ $w->{nodeid} };
        $w->pushOtputVar($vname);

        #set current namespace (used for {call})
        $self->ctx->{namespace} = $namespace;

        #parse template
        $self->visit_childs($t);
        $w->initOutputVar();
        $w->say("return \$$vname;");
        $w->dec_ident;
        $w->say('}');
        $w->say(''); # empty line

        #collect statistic
        push @{ $self->{tmpls} },
          {
            tmpl         => $t,
            namespace    => $namespace,
            name         => $tmpl_name,
            perl5_name   => $converted_name,
            package_name => $self->{package} . "::" . $converted_name,
          };
        # clear current template PARAMS
        delete $self->{PARAMS};

    }
}
sub command_foreach {
    my ($self, $n) = @_;
    my $w    = $self->wr;
#    die Dumper $self->ctx;
    my $vname = $n->get_var_name();
    my $id = ++${ $w->{nodeid} };
    my $list_var =  "list_". $vname. $id;
    my $list_len_var = "len_". $vname. $id;
    my $exp = $n->{expression}->parse($w->var_map, $self->{PARAMS})->as_perl5();
    $w->say("my \$$list_var = ". $exp .";");
    $w->say("my \$$list_len_var = scalar(\@\$$list_var);");
    $w->initOutputVar();
    #check ifempty
    if ($n->get_ifempty) {
        $w->say("if ( \$$list_len_var > 0 ) {");
        $w->inc_ident();
    }
    #export foreach
    my $index_var_name = "idx_$vname".$id;
    $w->say("for (my \$$index_var_name = 0; \$$index_var_name < \$$list_len_var; \$$index_var_name++) {");
        $w->inc_ident();
        my $data_var_name = "data_$vname".$id;
        #map tempalte variable to actual name
        $w->set_var_map($vname,$data_var_name);
        #data variable
        $w->say("my \$$data_var_name = \$$list_var\->[\$$index_var_name];");
        $self->visit_childs($n);
        $w->dec_ident();
        $w->say('}');
    if (my $ifempty_node = $n->get_ifempty) {
        $w->dec_ident();
        $w->say('} else {');
        $w->inc_ident();
        $w->say('#ifempty content');
        $self->visit_childs($ifempty_node);
        $w->dec_ident();
        $w->say('} # ifempty');
     }

}

sub command_print {
    my ( $self, $n ) = @_;
    my $w    = $self->wr;
    my $p5_code = $n->{expression}->parse($w->var_map, , $self->{PARAMS})->as_perl5();
    $w->appendOutputVar($p5_code)
}

use Perl6::Pod::To::XHTML; 
use Perl6::Pod::To;
use Perl6::Pod::Lib;
#pod6xhtml  -nb -t div -M Perl6::Pod::Lib -c \'=Include $file($rule)'
sub command_import {
    my ( $self, $n ) = @_;
    my $w    = $self->wr;
    my $file = $n->attrs->{file};
    my $rule = $n->attrs->{rule} || '';
    unless (-e $file ) {
        die "File for import : $file not found!"
    }
    my %args = (doctype =>'div', body=>0);
    my  $in_fd = "=Include $file" .( $rule ? "($rule)" : '');
    $in_fd = \"=begin pod \n$in_fd\n=end pod";
    my $str ='';
    open FH,'>',\$str;
    my $p = Perl6::Pod::To::to_abstract( 'Perl6::Pod::To::XHTML', \*FH, %args );
    $p->begin_input;
    #include libs ( see $Perl6::Pod::Lib::PERL6POD )
    my @libs = (qw/Perl6::Pod::Lib/);
    if (@libs) {
        my $use  = join "\n" => map { "=begin pod\n=use $_\n=end pod" } @libs;
        $use .= "\n";
        $p->_parse_chunk(\$use);
    }
    $p->_parse_chunk($in_fd);
    $p->end_input;
    close FH;
    #replace ' -> \'
    $str =~ s/\'/\\'/g;
    $w->appendOutputVar( qq!'$str'! );
}


1;
__END__

=head1 SEE ALSO

Closure Templates Documentation L<http://code.google.com/closure/templates/docs/overview.html>

Perl 6 implementation L<https://github.com/zag/plosurin>


=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


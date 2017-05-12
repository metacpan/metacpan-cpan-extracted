package Solstice::Compiler::View;

# $Id: View.pm 2944 2006-01-07 00:37:15Z pmichaud $

=head1 NAME

Solstice::Compiler::View - Compiles a View and Template into a perl structure

=head1 SYNOPSIS

  my $compiler = Solstice::Compiler::View->new();
  my $paint_method = $compiler->makePaintMethod($view_object);

=head1 DESCRIPTION

This module will take a Solstice::View object and the HTML::Template template that it specifies, and create a paint method for the view.

We do this because painting a template is very expensive... on complicated screens we were seeing %50 of page creation time in template painting.

The compiled paint methods will end up in the path specified in the compiled_template_path in the app's configuration file.  If there is no path specified, no compiled view will be made.

The goal of this module to support the syntax of HTML::Template, at least for some limited uses.  It is heavily biased towards the parts of HTML::Template that we use, it is very possible that there will be bugs in other parts of the syntax.  We will try to fix such bugs, provided they don't have a noticable impact on the performance of the compiled paint method.

Very important note - this will not work for modules that choose their templates dynamically.  You should change those so views are chosen dynamically, or disable compiled views for that application.

=cut

use 5.006_000;
use strict;
use warnings;

our ($VERSION) = ('$Revision: 2944 $' =~ /^\$Revision:\s*([\d.]*)/);

use constant TRUE  => 1;
use constant FALSE => 0;

use Solstice::ConfigService;

=head2 Methods

=over 4

=item new()

constructor.

=cut


sub new {
    my $obj = shift;
    my $self = bless {}, ref $obj || $obj;

    return $self;
}

=item makePaintMethod($package_name)

Takes a package name, and creates a paint method based on the template it uses.

=cut

sub makePaintMethod {
    my $self = shift;
    my $view_obj = shift;
    
    my $time = time;

    my @potential_templates = @{$view_obj->getPossibleTemplates()};
    my $template_base = $view_obj->_createTemplatePath();
    
    my $paint_method = "sub paint {\nmy \$self = shift;\nmy \$screen_ref = shift;\n";

    my $is_remote_view = UNIVERSAL::isa($view_obj, "Solstice::View::Remote") || 0;

    if (!scalar @potential_templates) {
        push @potential_templates, $view_obj->_getTemplate();
    }

    if (scalar @potential_templates) {
        $paint_method .= "my \$template = \$self->_getTemplate();\n
        if (\$Solstice::View::check_template_freshness && \$self->_needsCompilation($time) ) {
            return \$self->_compilePaint(\$screen_ref);
        }
        if(\$Solstice::View::use_wireframes && !$is_remote_view && ref(\$self) !~ m/^Solstice::View::Application\$/){ 
            \$\$screen_ref .= '<div class=\"solwireframe\"><div class=\"solwireframetxt\">'.ref(\$self).'</div>';
        }    
        no warnings;\nmy \$data = \$self->_getTemplateParams();\n";

        my $count = 0;
        foreach my $template (@potential_templates) {
            if (0 == $count) {
                $paint_method .= "if (\$template eq '$template') {\n";
            }
            else {
                $paint_method .= "elsif (\$template eq '$template') {\n";
            }
            my $template_path = $template_base . '/' . $template;
            $paint_method .= $self->_compileTemplate($template_path, $view_obj);
            $paint_method .= $self->_addTemplateErrors($template_path);
            $paint_method .= "}\n";
            $count++;
        }
        my $config = Solstice::ConfigService->new();
        my ($class_package) = split (/=/, $view_obj);
        my $error_message = "'Invalid template used: '.\$template.'.  Add a setPossibleTemplates call to $class_package'.\"\\n\";"; 
        $paint_method .= "else {\nwarn $error_message \n";
        if ($config->getDevelopmentMode()) {
            $paint_method .= "\$\$screen_ref .= $error_message \n";
        }
        $paint_method .= "}\n";
    }
    
    $paint_method .= "
    if(\$Solstice::View::use_wireframes && !$is_remote_view && ref(\$self) !~ m/^Solstice::View::Application\$/){ 
        \$\$screen_ref .= '</div>';
    }\n}\n";
    
    return $paint_method;
}

sub _addTemplateErrors {
    my $self = shift;
    my $template_path = shift;

    return '' unless $self->_getHasError();

    my $config = Solstice::ConfigService->new();

    return '' unless $config->getDevelopmentMode();

    my $return = "\$\$screen_ref .= '<div class=\"solwireframe\">Error parsing $template_path: <ul>";
    foreach (@{$self->_getErrors()}) {
        $return .= "<li>$_</li>\n";
    }
    $return .= "</ul></div>';";

    return $return;
}

sub _compileTemplate {
    my $self = shift;
    my $template_path = shift;
    my $view_obj = shift;

    my $paint_method = '';
    
    open (my $TEMPLATE, '<', $template_path) or die "Couldn't open template file $template_path for reading.\n";
    my $template_html = join('', <$TEMPLATE>);
    close ($TEMPLATE);
    
    my @template_sections;
    my $last_index = 0;
    
    while ((my $index = index($template_html, '<!--', $last_index)) > -1) {
    
        my $next_open_index = index($template_html, '<!--', $index+1);
        my $close_index = index($template_html, '-->', $index);
        my $has_closing = 0;


        # For when jokers do things like this: <!-- <!-- tmpl_var ... --> for variables inside of javascript
        if ($next_open_index > -1 && $next_open_index < $close_index) {
            $close_index = $next_open_index;
        }
        else {
            $has_closing = 1;
        }
        if (-1 == $close_index) {

            my $template_to_section = substr($template_html, 0, $index);
            my $line_number = () = $template_to_section =~ /\n/g;
            $line_number++;
            return $self->_addError("No close to a template tag in $template_path started at line $line_number");
        }
        
        # This finds the line number by generating a substring of the template up to our current location, 
        # and then counting the line breaks.  This could be improved by moving to a more traditional parser/compiler
        # arrangment.
        my $template_to_section = substr($template_html, 0, $last_index);
        my $line_number = () = $template_to_section =~ /\n/g;
        push @template_sections, {
                                   line_number => $line_number + 1,
                                   content     => substr($template_html, $last_index, $index-$last_index)
                                 };
        if (1 == $has_closing) {
            my $template_to_section = substr($template_html, 0, $index);
            my $line_number = () = $template_to_section =~ /\n/g;
            
            push @template_sections, { 
                                       line_number => $line_number + 1,
                                       content     => substr($template_html, $index, $close_index-$index+3)
                                     };
            $last_index = $close_index+3;
        }
        else {
            my $template_to_section = substr($template_html, 0, $index);
            my $line_number = () = $template_to_section =~ /\n/g;

            push @template_sections, { 
                                       line_number => $line_number + 1,
                                       content     => substr($template_html, $index, $close_index-$index)
                                     }; 
              
            $last_index = $close_index;
        }
        
    }
    my $template_to_section = substr($template_html, 0, $last_index);
    my $line_number = () = $template_to_section =~ /\n/g;
    push @template_sections, {
                                line_number => $line_number,
                                content     =>substr($template_html, $last_index)
                             };


    my $in_printing = 0;
    my $if_depth = 0;
    my $loop_depth = 0;
    my $unless_depth = 0;
    my $elseable_count = 0;
    my $data_base = '$data->';

    my @loop_stack;
    my @if_stack;
    my @unless_stack;
    
    my %valid_types = ('var' => 1, 'if' => 1, 'unless' => 1, 'else' => 1, 'loop' => 1, 'lang' =>1);
    foreach (@template_sections) {
        my $content     = $_->{'content'};
        my $line_number = $_->{'line_number'};
        next unless $content;
        if ($content =~ /^<!--\s*([\/]{0,1})tmpl_([a-z]+)+\s*([\w\W]*)\s*-->$/i) {
            warn "Deprecated use of tmpl_$2 in $template_path at line $line_number (use sol_$2 instead)\n";
            $content =~ s/^<!--\s*([\/]{0,1})tmpl_([a-z]+)+\s*([\w\W]*)\s*-->$/<!-- $1sol_$2 $3 -->/i;
        }
        if ($content =~ /^<!--\s*([\/]{0,1})sol_([a-z]+)+\s*([\w\W]*)\s*-->$/i) {
            my $end_statement = $1;
            my $type = lc($2);
            my $data = $3;
            my ($label, $value) = split(/=/, $data);
            $value = $data unless $value;
            if (defined $value and $value) {
                $value =~ s/^\s*//;
                $value =~ s/\s*$//;
                $value =~ s/[^0-9a-z_\-]//gi;
            }
            if (!defined $valid_types{$type}) {
                return $self->_addError("Invalid template command: sol_$type in $template_path at line $line_number");
            }
            if ('var' eq $type) {
                if ($in_printing) {
                    $paint_method .= "'.".$data_base."{'$value'}.'";
                }
                else {
                    $in_printing = 1;
                    $paint_method .= "\$\$screen_ref .= ".$data_base."{'$value'}.'";
                }
            }
            else {
                if ($in_printing) {
                    $paint_method .= "';\n";
                    $in_printing = 0;
                }
            }

            if ('lang' eq $type) {

                if($view_obj->can('useThemesLangfile') && $view_obj->useThemesLangfile()){
                    $paint_method .= "\$\$screen_ref .= \$self->getLangService('Themes')->getString('$value', \$self->{_params}, undef, '$template_path at line $line_number');\n";
                }else{
                    $paint_method .= "
                    \$\$screen_ref .= \$self->getLangService()->getString('$value', \$self->{_params}, undef, '$template_path at line $line_number');\n";
                }
            }

            if ('if' eq $type) {
                if ($end_statement) {
                    if ($if_depth < 1) {
                        return $self->_addError("/sol_if without matching sol_if in $template_path at line $line_number");
                    }
                    $if_depth--;
                    if ($elseable_count > 0) {
                        $elseable_count--;
                    }
                    pop @if_stack;
                    $paint_method .= "}\n";
                }
                else {
                    push @if_stack, $line_number;
                    $if_depth++;
                    $elseable_count++;
                    if ($in_printing) {
                        $paint_method .= "';\n";
                    }
                    if (lc($value) eq '__odd__') {
                        $paint_method .= "if (\$is_odd) {\n";
                    }
                    elsif (lc($value) eq '__even__') {
                        $paint_method .= "if (\$is_even) {\n";
                    }
                    elsif (lc($value) eq '__first__') {
                        $paint_method .= "if (\$is_first) {\n";
                    }
                    elsif (lc($value) eq '__last__') {
                        $paint_method .= "if (\$is_last) {\n";
                    }
                    else {
                        $paint_method .= "if ((ref ".$data_base."{'$value'} eq 'ARRAY' && scalar \@{".$data_base."{'$value'}}) || (ref ".$data_base."{'$value'} ne 'ARRAY' && ".$data_base."{'$value'})) {\n" if (defined $value); 
                    }
                }
            }
            if ('unless' eq $type) {
                if ($end_statement) {
                    if ($unless_depth < 1) {
                        return $self->_addError("/sol_unless without matching sol_unless in $template_path at line $line_number");
                    }
                    $unless_depth--;
                    if ($elseable_count > 0) {
                        $elseable_count--;
                    }
                    pop @unless_stack;
                    $paint_method .= "}\n";
                }
                else {
                    push @unless_stack, $line_number;
                    $unless_depth++;
                    $elseable_count++;
                    if ($in_printing) {
                        $paint_method .= "';\n";
                    }
                    if (lc($value) eq '__odd__') {
                        $paint_method .= "unless (\$is_odd) {\n";
                    }
                    elsif (lc($value) eq '__even__') {
                        $paint_method .= "unless (\$is_even) {\n";
                    }
                    elsif (lc($value) eq '__first__') {
                        $paint_method .= "unless (\$is_first) {\n";
                    }
                    elsif (lc($value) eq '__last__') {
                        $paint_method .= "unless (\$is_last) {\n";
                    }
                    else {
                        $paint_method .= "unless (".$data_base."{'$value'}) {\n";
                    }
                }
            }
            if ('else' eq $type) {
                if ($end_statement) {
                    return $self->_addError("Invalid command /else in $template_path at line $line_number");
                }
                if ($elseable_count < 1) {
                    return $self->_addError("else without if or unless in $template_path at line $line_number");
                }
                $paint_method .= "} else { \n";
            }
            if ('loop' eq $type) {
                if ($end_statement) {
                    if ($loop_depth < 1) {
                        return $self->_addError("/sol_loop without match sol_loop in $template_path at line $line_number");
                    }
                    pop @loop_stack;
                    $loop_depth--;
                    $paint_method .= "}\n}\n";
                    $data_base = $self->_lastData();
                }
                else {
                    push @loop_stack, $line_number;
                    $loop_depth++;

                    $paint_method .= "if (defined ".$data_base."{'$value'} and ref ".$data_base."{'$value'} ne 'ARRAY') { warn 'Non-array ref given for loop variable: $value.  Value: '.".$data_base."{'$value'}; } elsif (defined ".$data_base."{'$value'} and ref ".$data_base."{'$value'} eq 'ARRAY') { for (my \$size = scalar \@{".$data_base."{'$value'}}, my \$counter = 0, my \$is_odd = 1, my \$is_even = 0, my \$is_first = 1, my \$is_last = (scalar \@{".$data_base."{'$value'}} == 1), my \$entry_$loop_depth = ".$data_base."{'$value'}->[0]; \$counter < \$size; \$counter++, \$entry_$loop_depth = ".$data_base."{'$value'}->[\$counter], \$is_even = (\$counter % 2 == 1), \$is_odd = !\$is_even, \$is_first = \$counter == 0, \$is_last = \$size == \$counter+1 ) {";
                    $self->_addData($data_base);
                    $data_base = '$entry_'.$loop_depth.'->';
                }
            }
        }
        else {
            if (!$in_printing) {
                $paint_method .= "\$\$screen_ref .= '";
                $in_printing = 1;
            }
            $content =~ s/\\/\\\\/g;
            $content =~ s/'/\\'/g;
            $content =~ s/\n/'."\\n".'/g;
            $content =~ s/\r//g;
            $paint_method .= $content;
        }
    }

    my $bad_stack = FALSE;
    foreach (@if_stack) {
        $self->_addError("sol_if without closing /sol_if in $template_path at line $_");
        $bad_stack = TRUE;
    }
    foreach (@unless_stack) {
        $self->_addError("sol_unless without closing /sol_unless in $template_path at line $_");
        $bad_stack = TRUE;
    }

    foreach (@loop_stack) {
        $self->_addError("sol_loop without closing /sol_loop in $template_path at line $_");
        $bad_stack = TRUE;
    }

    if ($bad_stack) {
        return;
    }

    if ($in_printing) {
        $paint_method .= "';\n";
    }

    return $paint_method;
}

sub _addError {
    my $self = shift;
    my $error = shift;

    warn "$error\n";
    
    if (!defined $self->{'_errors'}) {
        $self->{'_errors'} = [];
    }
    push @{$self->{'_errors'}}, $error;

    $self->_setHasError(TRUE);
    return;
}

sub _getErrors {
    my $self = shift;
    return $self->{'_errors'} || [];
}

sub _getHasError {
    my $self = shift;
    return $self->{'_has_error'} || FALSE;
}

sub _setHasError {
    my $self = shift;
    $self->{'_has_error'} = TRUE;
}

sub _addData {
    my $self = shift;
    my $add_me = shift;
    push @{$self->{'data_base_history'}}, $add_me;
}

sub _lastData {
    my $self = shift;
    return pop @{$self->{'data_base_history'}};
}
1;

__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2944 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut

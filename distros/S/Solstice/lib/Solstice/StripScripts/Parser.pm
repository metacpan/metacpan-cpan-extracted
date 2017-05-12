package Solstice::StripScripts::Parser;

## no critic
#This code is constrained by being a subclass of a stripscripts class - we can't apply our styles to it

# $Id: Parser.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::StripScripts::Parser - Custom HTML whitelist for use in web content formatting.

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use Solstice::StripScripts;

use HTML::Parser;

our @ISA = qw(Solstice::StripScripts HTML::Parser);
our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::StripScripts|Solstice::StripScripts>,
L<HTML::Parser|HTML::Parser>.

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


sub hss_init {
    my ($self, $cfg, @parser_options) = @_;

    $self->init(
        @parser_options,

        api_version      => 3,
        start_document_h => ['input_start_document', 'self'],
        start_h          => ['input_start',          'self,text'],
        end_h            => ['input_end',            'self,text'],
        text_h           => ['input_text',           'self,text'],
        default_h        => ['input_text',           'self,text'],
        declaration_h    => ['input_declaration',    'self,text'],
        comment_h        => ['input_comment',        'self,text'],
        process_h        => ['input_process',        'self,text'],
        end_document_h   => ['input_end_document',   'self'],

        # workaround for http://rt.cpan.org/NoAuth/Bug.html?id=3954
        ( $HTML::Parser::VERSION =~ /^3\.(29|30|31)$/
            ?  ( strict_comment => 1 )
            :  ()
        ),
    );

    # Custom whitelist for css class
    $self->{'_hssClass'} = $self->init_class_whitelist;
    
    $self->SUPER::hss_init($cfg);
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::StripScripts|Solstice::StripScripts>,
L<HTML::Parser|HTML::Parser>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $



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

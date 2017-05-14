use strict ;
; package Bundle::Template::Magic


__END__

=pod

=head1 NAME

Bundle::Template::Magic - A bundle to install MagicTemplate distribution plus all related extensions and prerequisites.

=head1 SYNOPSIS

    perl -MCPAN -e 'install Bundle::Template::Magic'

=head1 CONTENTS

HTML::Tagset            - used by HTML::Parser

HTML::Parser            - used by HTML::FillInForm and HTML::TableTiler

HTML::TableTiler        - used by HTML::MagicTemplate

HTML::FillInForm        - used by HTML::MagicTemplate

Class::constr           - used by Template::Magic::Zone

Class::props            - used by Template::Magic::Zone

Object::props           - used by Template::Magic::Zone

File::Spec              - used by Template::Magic

IO::Util                - used by Template::Magic

Template::Magic         - the main distribution

=head1 DESCRIPTION

This bundle gathers together Template::Magic and all the related extensions and prerequisites.

Note: A Bundle is a module that simply defines a collection of other modules. It is used by the CPAN module to automate the fetching, building and installing of modules from the CPAN ftp archive sites.

=head1 AUTHOR and COPYRIGHT

© 2004-2005 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut

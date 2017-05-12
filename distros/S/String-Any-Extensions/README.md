# String-Any-Extensions
Get extensions from string possible for files.

# SYNOPSIS
    
    ...
    use String::Any::Extensions qw/include exclude/;
    #returns true
    include('some_string.ext.ext2', ['.ext','.ext.ext2']);
    #returns false
    exclude('some_string.ext.ext2', ['.ext','.ext.ext2']);
    #returns false '.ext.ext2'
    extension('some_string.ext.ext2');
    ...
 
# AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

# BUGS

Please report any bugs or feature requests to C<bug-String-Any-Extensions at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Any-Extensions>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Any::Extensions


You can also look for information at:

* RT: CPAN's request tracker (report bugs here) <http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Any-Extensions>

* AnnoCPAN: Annotated CPAN documentation <http://annocpan.org/dist/String-Any-Extensions>

* CPAN Ratings <http://cpanratings.perl.org/d/String-Any-Extensions>

* Search CPAN <http://search.cpan.org/dist/String-Any-Extensions/>

# SEE ALSO
 
+ List::Filter::Library::FileExtensions
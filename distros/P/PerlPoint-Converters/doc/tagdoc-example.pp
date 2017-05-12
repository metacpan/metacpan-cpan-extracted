
// This example demonstrates how to build a tag documentation
// using the provided functions (and basic tag docs).

// load function definition
\INCLUDE{file="doc-functions.pp" type=pp}


// open tag doc chapter
=Supported tags

This chapter documents all tags supported by pp2html.

// call the function to process the docs in chapter "tags".
\EMBED{lang=perl}includeDirectoryFiles('tags');\END_EMBED


# PDF::Table

This module creates and inserts text blocks and tables into PDF documents 
using the PDF::API2 or PDF::Builder Perl module.

## What is it?

PDF::Table is a library to format tables for insertion into PDF documents, 
using either the PDF::Builder or the PDF::API2 PDF-creation libraries, called 
from a Perl program. The PDF library (e.g., PDF::Builder) makes certain objects 
available to PDF::Table, as well as providing support services, and handles the 
overall PDF creation task. PDF::Table is called from within that a Perl program
using that library, to place tables of specific layout at the current active 
place on a document page. Tables may split across pages.

Note that PDF::Table, unlike PDF::Builder or PDF::API2, does not provide a set 
of low-level building blocks, but rather, is an all-in-one "table" call with 
very complex and flexible input. The table layout capability is a bit richer 
than that found in HTML/CSS, with a great deal of control over row, column, and 
cell properties, as well as rule and border formatting. With PDF::Builder as 
the underlying engine, PDF::Table cell content may be defined using Markdown or 
HTML markup languages. However, note that PDF::Table itself does not use HTML 
tag markup, nor does PDF::Builder currently support HTML table tags! The only 
way to put a table into a document is to invoke PDF::Table.

[Home Page](https://www.catskilltech.com/FreeSW/product/PDF%2DTable/title/PDF%3A%3ATable/freeSW_full), including Documentation and Examples.

[![Open Issues](https://img.shields.io/github/issues/PhilterPaper/PDF-Table)](https://github.com/PhilterPaper/PDF-Table/issues)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://makeapullrequest.com)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/PhilterPaper/PDF-Table/graphs/commit-activity)

The official repository for PDF::Table module collaboration:
"https://github.com/PhilterPaper/PDF-Table.git"

Any patches, pull requests, issues and feedback are more than welcome.

Do NOT under ANY circumstances open a PR (Pull Request) to **report a _bug_**. 
It is a waste of both _your_ and _our_ time and effort. Instead, simply open a 
regular ticket (_issue_), and attach a Perl (.pl) program illustrating the 
problem, if possible. 
If you believe that you have a program patch (i.e., a permanent change to the
code), and offer to share it as a PR, we may give the go-ahead. Unsolicited PRs 
may be closed without further action.

## Prerequisites

Required for installation: Test::More
Optional for installation: Test::Pod, Test::CheckManifest

Required for running: Carp, PDF::API2 and/or PDF::Builder
Optional for running: Pod::Simple::HTML

## Installation

To install the module from CPAN, please type the following command:

```cpanm PDF::Table```

To test or add features to this module, please type the following command:

```cpanm .```

## Changes
To see a list of changes, please do one or more of the following:
- Read the [Changes](Changes) file
- Review commits history on GitHub
- Make a diff from the tools menu at CPAN

## Contacts

- Use the issue tracker on GitHub, "https://github.com/PhilterPaper/PDF-Table/issues"
- See "https://metacpan.org/pod/PDF::Table" for distribution and more information

## License
Copyright (C) 2006 by Daemmon Hughes

Extended by Desislav Kamenov (Twitter @deskata) versions 0.02 - 0.11

Extended by Phil Perry since version 0.12
Copyright (C) 2020 - 2025 by Phil M Perry

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.
Note that Perl 5.10 is now the minimum for installation.

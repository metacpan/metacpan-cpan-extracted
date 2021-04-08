%%{
    machine rules;
    
    CRLF          = "\r\n";
    CTL           = cntrl | 127;
    SP            = ' ';
    HTAB          = '\t';
    WSP           = SP | HTAB;
    OWS           = WSP*; # optional whitespace
    VCHAR         = 0x21..0x7e; # visible characters (no whitespace)
    obs_text      = 0x80..0xFF;
    obs_fold      = CRLF WSP+; # obsolete line folding
    tchar         = alnum | "!" | "#" | "$" | "%" | "&" | "'" | "*" | "+" | "-" | "." | "^" | "_" | "`" | "|" | "~"; #any VCHAR, except delimiters
    token         = tchar+;
    qdtext        = WSP | 0x21 | 0x23..0x5B | 0x5D..0x7E | obs_text;
    quoted_pair   = "\\" (WSP | VCHAR | obs_text);
    quoted_string = '"' (qdtext | quoted_pair)* '"';
}%%
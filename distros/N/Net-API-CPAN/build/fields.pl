##----------------------------------------------------------------------------
## Meta CPAN API - ~/build/fields.pl
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/09/12
## Modified 2023/09/25
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# This is the master file containing all properties for each class used.
# From this file is created the fields.json file and then the api.json file
# 
# This program is free software; you can redistribute it and/or modify it under the same 
# terms as Perl itself.
{
    cpan_v1_01 =>
    {
        mappings =>
        {
            author =>
            {
                dynamic => \0,
                properties =>
                {
                    asciiname =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    blog =>
                    {
                        dynamic => \1,
                        properties =>
                        {
                            feed =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            url =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            }
                        }
                    },
                    city =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    country =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    donation =>
                    {
                        dynamic => \1,
                        properties =>
                        {
                            id =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            name =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            }
                        }
                    },
                    email =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    gravatar_url =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    is_pause_custodial_account =>
                    {
                        type => "boolean",
                    },
                    links =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    location =>
                    {
                        type => "geo_point",
                    },
                    name =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    pauseid =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    perlmongers =>
                    {
                        dynamic => \1,
                        properties =>
                        {
                            name =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            url =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            }
                        },
                        type => "array",
                    },
                    profile =>
                    {
                        dynamic => \0,
                        include_in_root => \1,
                        properties =>
                        {
                            id =>
                            {
                                fields =>
                                {
                                    analyzed =>
                                    {
                                        analyzer => "simple",
                                        fielddata =>
                                        {
                                            format => "disabled",
                                        },
                                        store => \1,
                                        type => "string",
                                    }
                                },
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            name =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            }
                        },
                        type => "nested",
                    },
                    release_count =>
                    {
                        properties =>
                        {
                            backpan-only =>
                            {
                                type => "integer",
                            },
                            cpan =>
                            {
                                type => "integer",
                            },
                            latest =>
                            {
                                type => "integer",
                            },
                        },
                    },
                    region =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    updated =>
                    {
                        format => "strict_date_optional_time||epoch_millis",
                        type => "date",
                    },
                    user =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    website =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    }
                }
            },
            changes =>
            {
                dynamic => \0,
                properties =>
                {
                    author =>
                    {
                        type => "string",
                    },
                    authorized =>
                    {
                        type => "boolean",
                    },
                    binary =>
                    {
                        type => "boolean",
                    },
                    category =>
                    {
                        type => "string",
                    },
                    content =>
                    {
                        type => "string",
                    },
                    date =>
                    {
                        type => "string",
                    },
                    deprecated =>
                    {
                        type => "boolean",
                    },
                    directory =>
                    {
                        type => "boolean",
                    },
                    dist_fav_count =>
                    {
                        type => "integer",
                    },
                    distribution =>
                    {
                        type => "string",
                    },
                    download_url =>
                    {
                        type => "string",
                    },
                    id =>
                    {
                        type => "string",
                    },
                    indexed =>
                    {
                        type => "boolean",
                    },
                    level =>
                    {
                        type => "integer",
                    },
                    maturity =>
                    {
                        type => "string",
                    },
                    mime =>
                    {
                        type => "string",
                    },
                    module =>
                    {
                        type => "array",
                    },
                    name =>
                    {
                        type => "string",
                    },
                    path =>
                    {
                        type => "string",
                    },
                    pod =>
                    {
                        type => "string",
                    },
                    pod_lines =>
                    {
                        type => "array",
                    },
                    release =>
                    {
                        type => "string",
                    },
                    sloc =>
                    {
                        type => "string",
                    },
                    slop =>
                    {
                        type => "string",
                    },
                    stat =>
                    {
                        properties =>
                        {
                            mode =>
                            {
                                type => "integer",
                            },
                            mtime =>
                            {
                                type => "integer",
                            },
                            size =>
                            {
                                type => "integer",
                            }
                        }
                    },
                    status =>
                    {
                        type => "string",
                    },
                    version =>
                    {
                        type => "string",
                    },
                    version_numified =>
                    {
                        type => "float",
                    }
                }
            },
            changes_release =>
            {
                dynamic => \0,
                properties =>
                {
                    author =>
                    {
                        type => "string",
                    },
                    changes_file =>
                    {
                        type => "string",
                    },
                    changes_text =>
                    {
                        type => "string",
                    },
                    release =>
                    {
                        type => "string",
                    }
                }
            },
            contributor =>
            {
                properties =>
                {
                    pauseid =>
                    {
                        index => "not_analyzed",
                        ignore_above => 2048,
                        type => "string",
                    },
                    release_author =>
                    {
                        index => "not_analyzed",
                        ignore_above => 2048,
                        type => "string",
                    },
                    distribution =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    release_name =>
                    {
                        type => "string",
                        ignore_above => 2048,
                        index => "not_analyzed",
                    }
                },
                dynamic => "false",
            },
            cover =>
            {
                properties =>
                {
                    criteria =>
                    {
                        properties =>
                        {
                            branch =>
                            {
                                type => "float",
                            },
                            condition =>
                            {
                                type => "float",
                            },
                            statement =>
                            {
                                type => "float",
                            },
                            subroutine =>
                            {
                                type => "float",
                            },
                            total =>
                            {
                                type => "float",
                            }
                        }
                    },
                    distribution =>
                    {
                        ignore_above => 2048,
                        type => "string",
                    },
                    release =>
                    {
                        ignore_above => 2048,
                        type => "string",
                    },
                    url =>
                    {
                        ignore_above => 2048,
                        type => "string",
                    },
                    version =>
                    {
                        ignore_above => 2048,
                        type => "string",
                    }
                }
            },
            cve =>
            {
                dynamic => \0,
                properties =>
                {
                    affected_versions =>
                    {
                        type => "string"
                    },
                    cpansa_id =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    cves =>
                    {
                        type => "string",
                    },
                    description =>
                    {
                        type => "string",
                    },
                    distribution =>
                    {
                        index => "not_analyzed",
                        type => "string",
                    },
                    references =>
                    {
                        type => "string",
                    },
                    releases =>
                    {
                        index => "not_analyzed", type => "string"
                    },
                    reported =>
                    {
                        format => "strict_date_optional_time||epoch_millis",
                        type => "date" },
                    severity =>
                    {
                        type => "string"
                    },
                    versions =>
                    {
                        index => "not_analyzed",
                        type => "string"
                    },
                },
            },
            diff =>
            {
                dynamic => \0,
                properties =>
                {
                    # Optional property when comparing 2 file IDs
                    diff =>
                    {
                        type => "string",
                    },
                    source =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    statistics =>
                    {
                        properties =>
                        {
                            deletions =>
                            {
                                type => "integer",
                            },
                            diff =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            insertions =>
                            {
                                type => "integer",
                            },
                            source =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            target =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            }
                        },
                        type => "array",
                    },
                    target =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    }
                }
            },
            distribution =>
            {
                dynamic => \0,
                properties =>
                {
                    bugs =>
                    {
                        dynamic => \1,
                        properties =>
                        {
                            github =>
                            {
                                dynamic => \1,
                                properties =>
                                {
                                    active =>
                                    {
                                        type => "integer",
                                    },
                                    closed =>
                                    {
                                        type => "integer",
                                    },
                                    open =>
                                    {
                                        type => "integer",
                                    },
                                    source =>
                                    {
                                        ignore_above => 2048,
                                        index => "not_analyzed",
                                        type => "string",
                                    }
                                }
                            },
                            rt =>
                            {
                                dynamic => \1,
                                properties =>
                                {
                                    '<html>' =>
                                    {
                                        type => "double",
                                    },
                                    active =>
                                    {
                                        type => "integer",
                                    },
                                    closed =>
                                    {
                                        type => "integer",
                                    },
                                    # originally, this property name is 'new', but this is a reserved word for us in perl
                                    recent =>
                                    {
                                        type => "integer",
                                    },
                                    open =>
                                    {
                                        type => "integer",
                                    },
                                    patched =>
                                    {
                                        type => "integer",
                                    },
                                    rejected =>
                                    {
                                        type => "integer",
                                    },
                                    resolved =>
                                    {
                                        type => "integer",
                                    },
                                    source =>
                                    {
                                        ignore_above => 2048,
                                        index => "not_analyzed",
                                        type => "string",
                                    },
                                    stalled =>
                                    {
                                        type => "integer",
                                    }
                                }
                            }
                        }
                    },
                    external_package =>
                    {
                        dynamic => \1,
                        properties =>
                        {
                            cygwin =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            debian =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            fedora =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            }
                        }
                    },
                    name =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    river =>
                    {
                        dynamic => \1,
                        properties =>
                        {
                            bucket =>
                            {
                                type => "integer",
                            },
                            bus_factor =>
                            {
                                type => "integer",
                            },
                            immediate =>
                            {
                                type => "integer",
                            },
                            total =>
                            {
                                type => "integer",
                            }
                        }
                    }
                }
            },
            download_url =>
            {
                dynamic => \0,
                properties =>
                {
                    checksum_md5 =>
                    {
                        type => "string",
                    },
                    checksum_sha256 =>
                    {
                        type => "string",
                    },
                    date =>
                    {
                        description => "An ISO 8601 datetime",
                        type => "string",
                    },
                    download_url =>
                    {
                        type => "string",
                    },
                    release =>
                    {
                        type => "string",
                    },
                    status =>
                    {
                        type => "string",
                    },
                    version =>
                    {
                        type => "string",
                    }
                }
            },
            favorite =>
            {
                dynamic => \0,
                properties =>
                {
                    author =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    date =>
                    {
                        format => "strict_date_optional_time||epoch_millis",
                        type => "date",
                    },
                    distribution =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    id =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    release =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    user =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    }
                }
            },
            file =>
            {
                dynamic => \0,
                properties =>
                {
                    abstract =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    author =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    authorized =>
                    {
                        type => "boolean",
                    },
                    binary =>
                    {
                        type => "boolean",
                    },
                    category =>
                    {
                        type => "string",
                    },
                    date =>
                    {
                        format => "strict_date_optional_time||epoch_millis",
                        type => "date",
                    },
                    deprecated =>
                    {
                        type => "boolean",
                    },
                    description =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    dir =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    directory =>
                    {
                        type => "boolean",
                    },
                    dist_fav_count =>
                    {
                        type => "integer",
                    },
                    distribution =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            },
                            camelcase =>
                            {
                                analyzer => "camelcase",
                                store => \1,
                                type => "string",
                            },
                            lowercase =>
                            {
                                analyzer => "lowercase",
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    documentation =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            },
                            camelcase =>
                            {
                                analyzer => "camelcase",
                                store => \1,
                                type => "string",
                            },
                            edge =>
                            {
                                analyzer => "edge",
                                store => \1,
                                type => "string",
                            },
                            edge_camelcase =>
                            {
                                analyzer => "edge_camelcase",
                                store => \1,
                                type => "string",
                            },
                            lowercase =>
                            {
                                analyzer => "lowercase",
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    download_url =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    id =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    indexed =>
                    {
                        type => "boolean",
                    },
                    level =>
                    {
                        type => "integer",
                    },
                    maturity =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    mime =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    module =>
                    {
                        dynamic => \0,
                        include_in_root => \1,
                        properties =>
                        {
                            associated_pod =>
                            {
                                type => "string",
                            },
                            authorized =>
                            {
                                type => "boolean",
                            },
                            indexed =>
                            {
                                type => "boolean",
                            },
                            name =>
                            {
                                fields =>
                                {
                                    analyzed =>
                                    {
                                        analyzer => "standard",
                                        fielddata =>
                                        {
                                            format => "disabled",
                                        },
                                        store => \1,
                                        type => "string",
                                    },
                                    camelcase =>
                                    {
                                        analyzer => "camelcase",
                                        store => \1,
                                        type => "string",
                                    },
                                    lowercase =>
                                    {
                                        analyzer => "lowercase",
                                        store => \1,
                                        type => "string",
                                    }
                                },
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            version =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            version_numified =>
                            {
                                type => "float",
                            }
                        },
                        type => "nested",
                    },
                    name =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    path =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    pod =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                term_vector => "with_positions_offsets",
                                type => "string",
                            }
                        },
                        index => "no",
                        type => "string",
                    },
                    pod_lines =>
                    {
                        doc_values => \1,
                        ignore_above => 2048,
                        index => "no",
                        type => "array",
                    },
                    release =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            },
                            camelcase =>
                            {
                                analyzer => "camelcase",
                                store => \1,
                                type => "string",
                            },
                            lowercase =>
                            {
                                analyzer => "lowercase",
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    sloc =>
                    {
                        type => "integer",
                    },
                    slop =>
                    {
                        type => "integer",
                    },
                    stat =>
                    {
                        dynamic => \1,
                        properties =>
                        {
                            gid =>
                            {
                                type => "long",
                            },
                            mode =>
                            {
                                type => "integer",
                            },
                            mtime =>
                            {
                                type => "integer",
                            },
                            size =>
                            {
                                type => "integer",
                            },
                            uid =>
                            {
                                type => "long",
                            }
                        }
                    },
                    status =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    suggest =>
                    {
                        analyzer => "simple",
                        max_input_length => 50,
                        payloads => \1,
                        preserve_position_increments => \1,
                        preserve_separators => \1,
                        type => "completion",
                    },
                    version =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    version_numified =>
                    {
                        type => "float",
                    }
                }
            },
            mirror =>
            {
                properties =>
                {
                    aka_name =>
                    {
                        type => "string",
                    },
                    A_or_CNAME =>
                    {
                        type => "string",
                    },
                    ccode =>
                    {
                        type => "string",
                    },
                    city =>
                    {
                        type => "string",
                    },
                    contact =>
                    {
                        properties => 
                        {
                            contact_site =>
                            {
                                type => "string",
                            },
                            contact_user =>
                            {
                                type => "string",
                            }
                        }
                    },
                    continent =>
                    {
                        type => "string",
                    },
                    country =>
                    {
                        type => "string",
                    },
                    distance =>
                    {
                        type => "string",
                    },
                    dnsrr =>
                    {
                        type => "string",
                    },
                    freq =>
                    {
                        type => "string",
                    },
                    ftp =>
                    {
                        type => "string",
                    },
                    http =>
                    {
                        type => "string",
                    },
                    inceptdate =>
                    {
                        type => "string",
                    },
                    location =>
                    {
                        type => "string",
                    },
                    name =>
                    {
                        type => "string",
                    },
                    note =>
                    {
                        type => "string",
                    },
                    org =>
                    {
                        type => "string",
                    },
                    region =>
                    {
                        type => "string",
                    },
                    reitredate =>
                    {
                        type => "string",
                    },
                    rsync =>
                    {
                        type => "string",
                    },
                    src =>
                    {
                        type => "string",
                    },
                    tz =>
                    {
                        type => "string",
                    }
                }
            },
            mirrors =>
            {
                properties =>
                {
                    mirrors =>
                    {
                        properties =>
                        {
                            aka_name =>
                            {
                                type => "string",
                            },
                            A_or_CNAME =>
                            {
                                type => "string",
                            },
                            ccode =>
                            {
                                type => "string",
                            },
                            city =>
                            {
                                type => "string",
                            },
                            contact =>
                            {
                                properties => 
                                {
                                    contact_site =>
                                    {
                                        type => "string",
                                    },
                                    contact_user =>
                                    {
                                        type => "string",
                                    }
                                }
                            },
                            continent =>
                            {
                                type => "string",
                            },
                            country =>
                            {
                                type => "string",
                            },
                            distance =>
                            {
                                type => "string",
                            },
                            dnsrr =>
                            {
                                type => "string",
                            },
                            freq =>
                            {
                                type => "string",
                            },
                            ftp =>
                            {
                                type => "string",
                            },
                            http =>
                            {
                                type => "string",
                            },
                            inceptdate =>
                            {
                                type => "string",
                            },
                            location =>
                            {
                                type => "string",
                            },
                            name =>
                            {
                                type => "string",
                            },
                            note =>
                            {
                                type => "string",
                            },
                            org =>
                            {
                                type => "string",
                            },
                            region =>
                            {
                                type => "string",
                            },
                            reitredate =>
                            {
                                type => "string",
                            },
                            rsync =>
                            {
                                type => "string",
                            },
                            src =>
                            {
                                type => "string",
                            },
                            tz =>
                            {
                                type => "string",
                            }
                        }
                    },
                    took =>
                    {
                        type => "integer",
                    },
                    total =>
                    {
                        type => "integer",
                    }
                }
            },
            module =>
            {
                dynamic => \0,
                properties =>
                {
                    abstract =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    author =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    authorized =>
                    {
                        type => "boolean",
                    },
                    binary =>
                    {
                        type => "boolean",
                    },
                    date =>
                    {
                        format => "strict_date_optional_time||epoch_millis",
                        type => "date",
                    },
                    deprecated =>
                    {
                        type => "boolean",
                    },
                    description =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    dir =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    directory =>
                    {
                        type => "boolean",
                    },
                    dist_fav_count =>
                    {
                        type => "integer",
                    },
                    distribution =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            },
                            camelcase =>
                            {
                                analyzer => "camelcase",
                                store => \1,
                                type => "string",
                            },
                            lowercase =>
                            {
                                analyzer => "lowercase",
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    documentation =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            },
                            camelcase =>
                            {
                                analyzer => "camelcase",
                                store => \1,
                                type => "string",
                            },
                            edge =>
                            {
                                analyzer => "edge",
                                store => \1,
                                type => "string",
                            },
                            edge_camelcase =>
                            {
                                analyzer => "edge_camelcase",
                                store => \1,
                                type => "string",
                            },
                            lowercase =>
                            {
                                analyzer => "lowercase",
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    download_url =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    id =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    indexed =>
                    {
                        type => "boolean",
                    },
                    level =>
                    {
                        type => "integer",
                    },
                    maturity =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    mime =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    module =>
                    {
                        dynamic => \0,
                        include_in_root => \1,
                        properties =>
                        {
                            associated_pod =>
                            {
                                type => "string",
                            },
                            authorized =>
                            {
                                type => "boolean",
                            },
                            indexed =>
                            {
                                type => "boolean",
                            },
                            name =>
                            {
                                fields =>
                                {
                                    analyzed =>
                                    {
                                        analyzer => "standard",
                                        fielddata =>
                                        {
                                            format => "disabled",
                                        },
                                        store => \1,
                                        type => "string",
                                    },
                                    camelcase =>
                                    {
                                        analyzer => "camelcase",
                                        store => \1,
                                        type => "string",
                                    },
                                    lowercase =>
                                    {
                                        analyzer => "lowercase",
                                        store => \1,
                                        type => "string",
                                    }
                                },
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            version =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            version_numified =>
                            {
                                type => "float",
                            }
                        },
                        type => "nested",
                    },
                    name =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    path =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    pod =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                term_vector => "with_positions_offsets",
                                type => "string",
                            }
                        },
                        index => "no",
                        type => "string",
                    },
                    pod_lines =>
                    {
                        doc_values => \1,
                        ignore_above => 2048,
                        index => "no",
                        type => "string",
                    },
                    release =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            },
                            camelcase =>
                            {
                                analyzer => "camelcase",
                                store => \1,
                                type => "string",
                            },
                            lowercase =>
                            {
                                analyzer => "lowercase",
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    sloc =>
                    {
                        type => "integer",
                    },
                    slop =>
                    {
                        type => "integer",
                    },
                    stat =>
                    {
                        dynamic => \1,
                        properties =>
                        {
                            gid =>
                            {
                                type => "long",
                            },
                            mode =>
                            {
                                type => "integer",
                            },
                            mtime =>
                            {
                                type => "integer",
                            },
                            size =>
                            {
                                type => "integer",
                            },
                            uid =>
                            {
                                type => "long",
                            }
                        }
                    },
                    status =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    suggest =>
                    {
                        analyzer => "simple",
                        max_input_length => 50,
                        payloads => \1,
                        preserve_position_increments => \1,
                        preserve_separators => \1,
                        type => "completion",
                    },
                    version =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    version_numified =>
                    {
                        type => "float",
                    }
                }
            },
            package =>
            {
                dynamic => \0,
                properties =>
                {
                    author =>
                    {
                        type => "string",
                    },
                    dist_version =>
                    {
                        type => "string",
                    },
                    distribution =>
                    {
                        type => "string",
                    },
                    file =>
                    {
                        type => "string",
                    },
                    module_name =>
                    {
                        type => "string",
                    },
                    version =>
                    {
                        description => "The numified version number",
                        type => "string",
                    }
                }
            },
            permission =>
            {
                dynamic => \0,
                properties =>
                {
                    co_maintainers =>
                    {
                        type => "string",
                    },
                    module_name =>
                    {
                        type => "string",
                    },
                    owner =>
                    {
                        type => "string",
                    },
                }
            },
            rating =>
            {
                dynamic => \0,
                properties =>
                {
                    author =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    date =>
                    {
                        format => "strict_date_optional_time||epoch_millis",
                        type => "date",
                    },
                    details =>
                    {
                        dynamic => \0,
                        properties =>
                        {
                            documentation =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            }
                        }
                    },
                    distribution =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    helpful =>
                    {
                        dynamic => \0,
                        properties =>
                        {
                            user =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            value =>
                            {
                                type => "boolean",
                            }
                        }
                    },
                    rating =>
                    {
                        type => "float",
                    },
                    release =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    user =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    }
                }
            },
            release =>
            {
                dynamic => \0,
                properties =>
                {
                    abstract =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    archive =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    author =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    authorized =>
                    {
                        type => "boolean",
                    },
                    changes_file =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    checksum_md5 =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    checksum_sha256 =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    date =>
                    {
                        format => "strict_date_optional_time||epoch_millis",
                        type => "date",
                    },
                    dependency =>
                    {
                        dynamic => \0,
                        include_in_root => \1,
                        properties =>
                        {
                            module =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            phase =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            relationship =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            version =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            }
                        },
                        type => "nested",
                    },
                    deprecated =>
                    {
                        type => "boolean",
                    },
                    distribution =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            },
                            camelcase =>
                            {
                                analyzer => "camelcase",
                                store => \1,
                                type => "string",
                            },
                            lowercase =>
                            {
                                analyzer => "lowercase",
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    download_url =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    first =>
                    {
                        type => "boolean",
                    },
                    id =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    license =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "array",
                    },
                    main_module =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    maturity =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    metadata =>
                    {
                        properties =>
                        {
                            abstract =>
                            {
                                ignore_above => 2048,
                                type => "string",
                            },
                            author =>
                            {
                                ignore_above => 2048,
                                type => "string",
                            },
                            dynamic_config =>
                            {
                                type => "boolean",
                            },
                            generated_by =>
                            {
                                ignore_above => 2048,
                                type => "string",
                            },
                            license => 
                            {
                                ignore_above => 2048,
                                type => "array",
                            },
                            meta-spec => 
                            {
                                properties =>
                                {
                                    url =>
                                    {
                                        ignore_above => 2048,
                                        type => "string",
                                    },
                                    version =>
                                    {
                                        type => "integer",
                                    }
                                },
                            },
                            name =>
                            {
                                ignore_above => 2048,
                                type => "string",
                            },
                            no_index =>
                            {
                                properties =>
                                {
                                    directory =>
                                    {
                                        ignore_above => 2048,
                                        type => "string",
                                    },
                                    package =>
                                    {
                                        ignore_above => 2048,
                                        type => "string",
                                    }
                                }
                            },
                            prereqs =>
                            {
                                properties =>
                                {
                                    build =>
                                    {
                                        properties =>
                                        {
                                            recommends =>
                                            {
                                                type => "nested",
                                            },
                                            requires =>
                                            {
                                                type => "nested",
                                            },
                                            suggests =>
                                            {
                                                type => "nested",
                                            }
                                        }
                                    },
                                    configure =>
                                    {
                                        properties =>
                                        {
                                            recommends =>
                                            {
                                                type => "nested",
                                            },
                                            requires =>
                                            {
                                                type => "nested",
                                            },
                                            suggests =>
                                            {
                                                type => "nested",
                                            }
                                        }
                                    },
                                    develop =>
                                    {
                                        properties =>
                                        {
                                            recommends =>
                                            {
                                                type => "nested",
                                            },
                                            requires =>
                                            {
                                                type => "nested",
                                            },
                                            suggests =>
                                            {
                                                type => "nested",
                                            }
                                        }
                                    },
                                    runtime =>
                                    {
                                        properties =>
                                        {
                                            recommends =>
                                            {
                                                type => "nested",
                                            },
                                            requires =>
                                            {
                                                type => "nested",
                                            },
                                            suggests =>
                                            {
                                                type => "nested",
                                            }
                                        }
                                    },
                                    test =>
                                    {
                                        properties =>
                                        {
                                            recommends =>
                                            {
                                                type => "nested",
                                            },
                                            requires =>
                                            {
                                                type => "nested",
                                            },
                                            suggests =>
                                            {
                                                type => "nested",
                                            }
                                        }
                                    }
                                }
                            },
                            release_status =>
                            {
                                ignore_above => 2048,
                                type => "string",
                            },
                            resources =>
                            {
                                properties => 
                                {
                                    bugtracker =>
                                    {
                                        properties =>
                                        {
                                            web =>
                                            {
                                                ignore_above => 2048,
                                                type => "string",
                                            },
                                            type =>
                                            {
                                                ignore_above => 2048,
                                                type => "string",
                                            }
                                        }
                                    },
                                    homepage =>
                                    {
                                        properties =>
                                        {
                                            web =>
                                            {
                                                ignore_above => 2048,
                                                type => "string",
                                            },
                                        },
                                    },
                                    license =>
                                    {
                                        type => "string",
                                    },
                                    repository =>
                                    {
                                        properties =>
                                        {
                                            url =>
                                            {
                                                ignore_above => 2048,
                                                type => "string",
                                            },
                                            type =>
                                            {
                                                ignore_above => 2048,
                                                type => "string",
                                            },
                                            web =>
                                            {
                                                ignore_above => 2048,
                                                type => "string",
                                            },
                                        }
                                    },
                                    x_IRC =>
                                    {
                                        ignore_above => 2048,
                                        type => "string",
                                    },
                                    x_MailingList =>
                                    {
                                        ignore_above => 2048,
                                        type => "string",
                                    },
                                },
                                type => "nested",
                            },
                            version =>
                            {
                                type => "string",
                            },
                            x_contributors =>
                            {
                                type => "array",
                            },
                            x_generated_by_perl =>
                            {
                                type => "string",
                            },
                            x_serialization_backend =>
                            {
                                type => "string",
                            },
                            x_spdx_expression =>
                            {
                                type => "string",
                            },
                            x_static_install =>
                            {
                                type => "string",
                            },
                        },
                        type => "nested",
                    },
                    name =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            },
                            camelcase =>
                            {
                                analyzer => "camelcase",
                                store => \1,
                                type => "string",
                            },
                            lowercase =>
                            {
                                analyzer => "lowercase",
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    provides =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    resources =>
                    {
                        dynamic => \1,
                        include_in_root => \1,
                        properties =>
                        {
                            bugtracker =>
                            {
                                dynamic => \1,
                                include_in_root => \1,
                                properties =>
                                {
                                    mailto =>
                                    {
                                        ignore_above => 2048,
                                        index => "not_analyzed",
                                        type => "string",
                                    },
                                    web =>
                                    {
                                        ignore_above => 2048,
                                        index => "not_analyzed",
                                        type => "string",
                                    }
                                },
                                type => "nested",
                            },
                            homepage =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "string",
                            },
                            license =>
                            {
                                ignore_above => 2048,
                                index => "not_analyzed",
                                type => "array",
                            },
                            repository =>
                            {
                                dynamic => \1,
                                include_in_root => \1,
                                properties =>
                                {
                                    type =>
                                    {
                                        ignore_above => 2048,
                                        index => "not_analyzed",
                                        type => "string",
                                    },
                                    url =>
                                    {
                                        ignore_above => 2048,
                                        index => "not_analyzed",
                                        type => "string",
                                    },
                                    web =>
                                    {
                                        ignore_above => 2048,
                                        index => "not_analyzed",
                                        type => "string",
                                    }
                                },
                                type => "nested",
                            }
                        },
                        type => "nested",
                    },
                    stat =>
                    {
                        dynamic => \1,
                        properties =>
                        {
                            gid =>
                            {
                                type => "long",
                            },
                            mode =>
                            {
                                type => "integer",
                            },
                            mtime =>
                            {
                                type => "integer",
                            },
                            size =>
                            {
                                type => "integer",
                            },
                            uid =>
                            {
                                type => "long",
                            }
                        }
                    },
                    status =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    tests =>
                    {
                        dynamic => \1,
                        properties =>
                        {
                            fail =>
                            {
                                type => "integer",
                            },
                            na =>
                            {
                                type => "integer",
                            },
                            pass =>
                            {
                                type => "integer",
                            },
                            unknown =>
                            {
                                type => "integer",
                            }
                        }
                    },
                    version =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    version_numified =>
                    {
                        type => "float",
                    }
                }
            },
            release_recent =>
            {
                dynamic => \0,
                properties =>
                {
                    abstract =>
                    {
                        type => "string",
                    },
                    author =>
                    {
                        type => "string",
                    },
                    date =>
                    {
                        type => "date",
                    },
                    distribution =>
                    {
                        type => "string",
                    },
                    name =>
                    {
                        type => "string",
                    },
                    maturity =>
                    {
                        type => "string",
                    },
                    status =>
                    {
                        type => "string",
                    }
                }
            },
            suggest =>
            {
                dynamic => \0,
                properties =>
                {
                    author =>
                    {
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    date =>
                    {
                        format => "strict_date_optional_time||epoch_millis",
                        type => "date",
                    },
                    deprecated =>
                    {
                        type => "boolean",
                    },
                    distribution =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            },
                            camelcase =>
                            {
                                analyzer => "camelcase",
                                store => \1,
                                type => "string",
                            },
                            lowercase =>
                            {
                                analyzer => "lowercase",
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                    name =>
                    {
                        type => "string",
                    },
                    release =>
                    {
                        fields =>
                        {
                            analyzed =>
                            {
                                analyzer => "standard",
                                fielddata =>
                                {
                                    format => "disabled",
                                },
                                store => \1,
                                type => "string",
                            },
                            camelcase =>
                            {
                                analyzer => "camelcase",
                                store => \1,
                                type => "string",
                            },
                            lowercase =>
                            {
                                analyzer => "lowercase",
                                store => \1,
                                type => "string",
                            }
                        },
                        ignore_above => 2048,
                        index => "not_analyzed",
                        type => "string",
                    },
                }
            }
        }
    }
}

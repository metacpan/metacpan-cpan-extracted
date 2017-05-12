# Copyright (c) 2016  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
use Test::More tests => 26;
use strict;
use warnings;

use_ok( 'SQL::Functional::Clause' );
use_ok( 'SQL::Functional::AndClause' );
use_ok( 'SQL::Functional::CountClause' );
use_ok( 'SQL::Functional::DistinctClause' );
use_ok( 'SQL::Functional::TruncateClause' );
use_ok( 'SQL::Functional::FieldClause' );
use_ok( 'SQL::Functional::FromClause' );
use_ok( 'SQL::Functional::GroupByClause' );
use_ok( 'SQL::Functional::InsertClause' );
use_ok( 'SQL::Functional::JoinClause' );
use_ok( 'SQL::Functional::LimitClause' );
use_ok( 'SQL::Functional::LiteralClause' );
use_ok( 'SQL::Functional::MatchClause' );
use_ok( 'SQL::Functional::NullClause' );
use_ok( 'SQL::Functional::OrClause' );
use_ok( 'SQL::Functional::OrderByClause' );
use_ok( 'SQL::Functional::PlaceholderClause' );
use_ok( 'SQL::Functional::UpdateClause' );
use_ok( 'SQL::Functional::ValuesClause' );
use_ok( 'SQL::Functional::VerbatimClause' );
use_ok( 'SQL::Functional::WhereClause' );
use_ok( 'SQL::Functional::WrapClause' );
use_ok( 'SQL::Functional::TruncateClause' );
use_ok( 'SQL::Functional::SelectClause' );
use_ok( 'SQL::Functional::SetClause' );
use_ok( 'SQL::Functional' );

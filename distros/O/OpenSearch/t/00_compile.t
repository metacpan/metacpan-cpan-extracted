use strict;
use Test::More 0.98;

use_ok $_ for qw(
  OpenSearch

  OpenSearch::Index
  OpenSearch::Index::ClearCache
  OpenSearch::Index::Clone
  OpenSearch::Index::Close
  OpenSearch::Index::Create
  OpenSearch::Index::Delete
  OpenSearch::Index::DeleteDangling
  OpenSearch::Index::Exists
  OpenSearch::Index::ForceMerge
  OpenSearch::Index::Get
  OpenSearch::Index::GetAliases
  OpenSearch::Index::GetDangling
  OpenSearch::Index::GetMappings
  OpenSearch::Index::GetSettings
  OpenSearch::Index::ImportDangling
  OpenSearch::Index::Open
  OpenSearch::Index::Refresh
  OpenSearch::Index::SetAliases
  OpenSearch::Index::SetMappings
  OpenSearch::Index::Shrink
  OpenSearch::Index::Split
  OpenSearch::Index::Stats
  OpenSearch::Index::UpdateSettings

  OpenSearch::Search
  OpenSearch::Remote
  OpenSearch::Document
  OpenSearch::Cluster
  OpenSearch::Response
);

done_testing;


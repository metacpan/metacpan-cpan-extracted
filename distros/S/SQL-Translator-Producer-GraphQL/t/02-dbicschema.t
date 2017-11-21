use strict;
use Test::More 0.98;
use File::Spec;
use lib 't/lib-dbicschema';
use Schema;
use SQL::Translator;

my $expected = join '', <DATA>;
my $dbic_class = 'Schema';
my $t = SQL::Translator->new(
  parser => 'SQL::Translator::Parser::DBIx::Class',
  parser_args => { dbic_schema => $dbic_class->connect },
  producer => 'GraphQL',
);
my $got = $t->translate or die $t->error;
#open my $fh, '>', 'tf'; print $fh $got; # uncomment to regenerate
is $got, $expected;

done_testing;

__DATA__
type BlogTags {
  blog: Blogs!
  id: Int!
  name: String!
}

input BlogTagsCreateInput {
  blog: BlogsMutateInput!
  name: String!
}

input BlogTagsMutateInput {
  id: Int!
  name: String
}

input BlogTagsSearchInput {
  name: String
}

type Blogs {
  content: String!
  created_time: String!
  get_blog_tags: [BlogTags]
  id: Int!
  location: String
  subtitle: String
  timestamp: DateTime!
  title: String!
}

input BlogsCreateInput {
  content: String!
  created_time: String!
  location: String
  subtitle: String
  timestamp: DateTime!
  title: String!
}

input BlogsMutateInput {
  content: String
  created_time: String
  id: Int!
  location: String
  subtitle: String
  timestamp: DateTime
  title: String
}

input BlogsSearchInput {
  content: String
  created_time: String
  location: String
  subtitle: String
  timestamp: DateTime
  title: String
}

type Mutation {
  createBlogTags(input: [BlogTagsCreateInput!]!): [BlogTags]
  createBlogs(input: [BlogsCreateInput!]!): [Blogs]
  createPhotos(input: [PhotosCreateInput!]!): [Photos]
  createPhotosets(input: [PhotosetsCreateInput!]!): [Photosets]
  deleteBlogTags(input: [BlogTagsMutateInput!]!): [Boolean]
  deleteBlogs(input: [BlogsMutateInput!]!): [Boolean]
  deletePhotos(input: [PhotosMutateInput!]!): [Boolean]
  deletePhotosets(input: [PhotosetsMutateInput!]!): [Boolean]
  updateBlogTags(input: [BlogTagsMutateInput!]!): [BlogTags]
  updateBlogs(input: [BlogsMutateInput!]!): [Blogs]
  updatePhotos(input: [PhotosMutateInput!]!): [Photos]
  updatePhotosets(input: [PhotosetsMutateInput!]!): [Photosets]
}

type Photos {
  country: String
  description: String
  get_photosets: [Photosets]
  id: String!
  idx: Int
  is_glen: String
  isprimary: String
  large: String
  lat: String
  locality: String
  lon: String
  medium: String
  original: String
  original_url: String
  photoset: Photosets
  region: String
  small: String
  square: String
  taken: DateTime
  thumbnail: String
}

input PhotosCreateInput {
  country: String
  description: String
  idx: Int
  is_glen: String
  isprimary: String
  large: String
  lat: String
  locality: String
  lon: String
  medium: String
  original: String
  original_url: String
  photoset: PhotosetsMutateInput
  region: String
  small: String
  square: String
  taken: DateTime
  thumbnail: String
}

input PhotosMutateInput {
  country: String
  description: String
  id: String!
  idx: Int
  is_glen: String
  isprimary: String
  large: String
  lat: String
  locality: String
  lon: String
  medium: String
  original: String
  original_url: String
  region: String
  small: String
  square: String
  taken: DateTime
  thumbnail: String
}

input PhotosSearchInput {
  country: String
  description: String
  idx: Int
  is_glen: String
  isprimary: String
  large: String
  lat: String
  locality: String
  lon: String
  medium: String
  original: String
  original_url: String
  region: String
  small: String
  square: String
  taken: DateTime
  thumbnail: String
}

type Photosets {
  can_comment: Int
  count_comments: Int
  count_views: Int
  date_create: Int
  date_update: Int
  description: String!
  farm: Int!
  get_photos: [Photos]
  id: String!
  idx: Int!
  needs_interstitial: Int
  photos: Int
  primary_photo: Photos
  secret: String!
  server: String!
  timestamp: DateTime!
  title: String!
  videos: Int
  visibility_can_see_set: Int
}

input PhotosetsCreateInput {
  can_comment: Int
  count_comments: Int
  count_views: Int
  date_create: Int
  date_update: Int
  description: String!
  farm: Int!
  idx: Int!
  needs_interstitial: Int
  photos: Int
  primary_photo: PhotosMutateInput
  secret: String!
  server: String!
  timestamp: DateTime!
  title: String!
  videos: Int
  visibility_can_see_set: Int
}

input PhotosetsMutateInput {
  can_comment: Int
  count_comments: Int
  count_views: Int
  date_create: Int
  date_update: Int
  description: String
  farm: Int
  id: String!
  idx: Int
  needs_interstitial: Int
  photos: Int
  secret: String
  server: String
  timestamp: DateTime
  title: String
  videos: Int
  visibility_can_see_set: Int
}

input PhotosetsSearchInput {
  can_comment: Int
  count_comments: Int
  count_views: Int
  date_create: Int
  date_update: Int
  description: String
  farm: Int
  idx: Int
  needs_interstitial: Int
  photos: Int
  secret: String
  server: String
  timestamp: DateTime
  title: String
  videos: Int
  visibility_can_see_set: Int
}

type Query {
  blogTags(id: [Int!]!): [BlogTags]
  blogs(id: [Int!]!): [Blogs]
  photos(id: [String!]!): [Photos]
  photosets(id: [String!]!): [Photosets]
  # input to search
  searchBlogTags(input: BlogTagsSearchInput!): [BlogTags]
  # input to search
  searchBlogs(input: BlogsSearchInput!): [Blogs]
  # input to search
  searchPhotos(input: PhotosSearchInput!): [Photos]
  # input to search
  searchPhotosets(input: PhotosetsSearchInput!): [Photosets]
}

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
  blog: Blogs
  id: Int!
  name: String!
}

input BlogTagsInput {
  blogs_id: Int!
  name: String!
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

input BlogsInput {
  content: String!
  created_time: String!
  location: String
  subtitle: String
  timestamp: DateTime!
  title: String!
}

scalar DateTime

type Mutation {
  createBlogTags(input: BlogTagsInput!): BlogTags
  createBlogs(input: BlogsInput!): Blogs
  createPhotos(input: PhotosInput!): Photos
  createPhotosets(input: PhotosetsInput!): Photosets
  deleteBlogTags(id: Int!): Boolean
  deleteBlogs(id: Int!): Boolean
  deletePhotos(id: String!): Boolean
  deletePhotosets(id: String!): Boolean
  updateBlogTags(id: Int!, input: BlogTagsInput!): BlogTags
  updateBlogs(id: Int!, input: BlogsInput!): Blogs
  updatePhotos(id: String!, input: PhotosInput!): Photos
  updatePhotosets(id: String!, input: PhotosetsInput!): Photosets
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

input PhotosInput {
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
  photosets_id: String!
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

input PhotosetsInput {
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
  photos_id: String!
  secret: String!
  server: String!
  timestamp: DateTime!
  title: String!
  videos: Int
  visibility_can_see_set: Int
}

type Query {
  blogTags(id: [Int!]!): [BlogTags]
  blogs(id: [Int!]!): [Blogs]
  photos(id: [String!]!): [Photos]
  photosets(id: [String!]!): [Photosets]
  # list of ORs each of which is list of ANDs
  searchBlogTags(input: [[BlogTagsInput!]!]!): [BlogTags]
  # list of ORs each of which is list of ANDs
  searchBlogs(input: [[BlogsInput!]!]!): [Blogs]
  # list of ORs each of which is list of ANDs
  searchPhotos(input: [[PhotosInput!]!]!): [Photos]
  # list of ORs each of which is list of ANDs
  searchPhotosets(input: [[PhotosetsInput!]!]!): [Photosets]
}

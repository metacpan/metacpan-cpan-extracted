#include <panda/protocol/http.h>
#include <catch2/catch_test_macros.hpp>
#include <catch2/matchers/catch_matchers_string.hpp>

using namespace panda;
using namespace panda::protocol::http;
using Catch::Matchers::StartsWith;
using Method = Request::Method;

#define TEST(name) TEST_CASE("brotli-compression: " name, "[brotli-compression]")

TEST("small body compress/uncompress") {
    auto req = Request::Builder()
        .method(Method::Post)
        .body("my body")
        .compress(Compression::BROTLI)
        .build();

    auto data = req->to_string();
    REQUIRE_THAT(data, StartsWith(
        "POST / HTTP/1.1\r\n"
        "Content-Length: 11\r\n"
        "Content-Encoding: br\r\n"
        "\r\n"
    ));
    CHECK(req->body.to_string() == "my body");

    SECTION("to_vector") {
        auto vec = req->to_vector();
        string buff;
        for(auto& it:vec) { buff += it; }
        CHECK(buff == req->to_string());
    }

    RequestParser p;
    auto result = p.parse(data);
    CHECK(result.state == State::done);
    CHECK(result.error.value() == 0);
    CHECK(req->compression.type == Compression::BROTLI);
    REQUIRE(req->body.to_string() == "my body");
}

TEST("average body") {
    const char * body_raw = R"END(
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse vel eros sit amet ex gravida tempor sit amet sit amet nisi. Sed ultrices, enim mattis sagittis tincidunt, tortor quam fermentum lectus, vitae mattis felis diam quis lorem. Suspendisse facilisis lorem dui, porta consectetur velit consectetur ac. Maecenas libero justo, porta in finibus vitae, blandit sed felis. Donec aliquam, leo eget ultrices tincidunt, purus ante ornare ipsum, sit amet auctor nunc ligula id nisi. Praesent sit amet sapien eget orci porta accumsan. Ut sed tortor ligula. Aliquam odio dolor, volutpat vitae elit eget, aliquet accumsan nisl. In ac placerat ligula.

In eu ultrices turpis, in porta risus. Sed erat dui, euismod in pellentesque in, auctor sit amet erat. Fusce consectetur fermentum neque, vel viverra mauris finibus efficitur. Donec blandit accumsan lacus sit amet viverra. In leo erat, mollis et laoreet eu, vulputate id odio. Suspendisse elementum blandit malesuada. Mauris in tellus lobortis, ullamcorper nulla at, elementum ligula. Vestibulum congue consequat tellus vel gravida. Nam in pharetra tortor, vel tempor tellus. Sed ac pulvinar odio, ac convallis augue. Pellentesque tortor dui, eleifend id ante eget, consequat faucibus felis. Nam vitae lacinia tortor. Praesent lacinia quam ac augue pretium, in auctor nunc consectetur. Cras est sapien, commodo quis tincidunt vitae, faucibus eget quam. Praesent placerat enim lectus, vitae cursus erat semper sed.

Fusce quis nulla lacus. Nulla non vulputate diam, eget pulvinar sapien. Vivamus congue tortor ut nulla ultrices, sit amet elementum dolor dignissim. Cras gravida, nisl vel venenatis lacinia, urna magna accumsan turpis, eu porta urna ex vel nulla. Integer ut malesuada ante, quis pulvinar risus. Aenean suscipit gravida ante quis vestibulum. Cras id enim a arcu tristique pretium. Ut euismod ante accumsan tempor sollicitudin. Nunc sed risus bibendum, congue ipsum a, ornare est. Pellentesque vitae est auctor, consectetur nunc at, viverra lectus. Sed nunc leo, ullamcorper eu tortor a, lacinia dapibus est. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Cras dictum vel odio at tempus. Mauris quam ligula, viverra eget semper et, ultricies vitae lectus. Maecenas quis libero nibh.

Duis congue lacus sit amet rutrum mollis. Donec facilisis mollis arcu vitae lobortis. Donec efficitur mi et diam fringilla finibus. Aenean rhoncus volutpat eleifend. Fusce dictum mauris nunc, at rutrum tortor convallis sed. Phasellus id consequat felis. Maecenas tincidunt nibh nisi, sed blandit velit egestas nec. Integer dapibus dolor felis, ac mollis massa mattis non. Curabitur nisi diam, viverra vel magna et, tempor feugiat tortor. Etiam eu nulla id orci posuere egestas nec non tortor.

Nullam quis tempus lectus. Quisque purus est, venenatis at auctor a, laoreet in purus. Ut convallis, odio eget ullamcorper sollicitudin, nunc felis consectetur erat, ac varius neque diam in magna. Aenean quis orci eu urna blandit laoreet. Pellentesque ultricies metus dui, a luctus justo dignissim a. Suspendisse interdum hendrerit facilisis. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean facilisis viverra tortor, et malesuada nisl hendrerit vitae. Duis magna ipsum, mattis in feugiat vitae, tristique eget elit. Vivamus quis arcu felis. Praesent et nunc quis dui dictum laoreet. Praesent auctor urna sit amet quam pulvinar fringilla. Integer in elit maximus, mollis neque a, tempor metus. Donec sodales sapien ut lorem tristique, tristique ultricies arcu porta. Morbi mi nisl, efficitur et fermentum vel, aliquam ac erat.
)END";
    string body_sample(body_raw);
    auto req = Request::Builder()
        .method(Method::Post)
        .body(body_sample)
        .compress(Compression::BROTLI, Compression::Level::max)
        .build();

    auto data = req->to_string();
    REQUIRE_THAT(data, StartsWith(
        "POST / HTTP/1.1\r\n"
        "Content-Length: 1469\r\n"
        "Content-Encoding: br\r\n"
        "\r\n"
    ));
    CHECK(req->body.to_string() == body_sample);
    RequestParser p;
    auto result = p.parse(data);
    CHECK(result.state == State::done);
    CHECK(result.error.value() == 0);
    CHECK(req->compression.type == Compression::BROTLI);
    REQUIRE(req->body.to_string() == body_sample);
}

TEST("real response sample") {
    unsigned char data[] = {
    0x48, 0x54, 0x54, 0x50, 0x2f, 0x31, 0x2e, 0x31,
    0x20, 0x32, 0x30, 0x30, 0x20, 0x4f, 0x4b, 0x0d,
    0x0a, 0x53, 0x65, 0x72, 0x76, 0x65, 0x72, 0x3a,
    0x20, 0x6e, 0x67, 0x69, 0x6e, 0x78, 0x0d, 0x0a,
    0x44, 0x61, 0x74, 0x65, 0x3a, 0x20, 0x4d, 0x6f,
    0x6e, 0x2c, 0x20, 0x32, 0x33, 0x20, 0x44, 0x65,
    0x63, 0x20, 0x32, 0x30, 0x31, 0x39, 0x20, 0x31,
    0x35, 0x3a, 0x33, 0x30, 0x3a, 0x34, 0x30, 0x20,
    0x47, 0x4d, 0x54, 0x0d, 0x0a, 0x43, 0x6f, 0x6e,
    0x74, 0x65, 0x6e, 0x74, 0x2d, 0x54, 0x79, 0x70,
    0x65, 0x3a, 0x20, 0x61, 0x70, 0x70, 0x6c, 0x69,
    0x63, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x2f, 0x6f,
    0x63, 0x74, 0x65, 0x74, 0x2d, 0x73, 0x74, 0x72,
    0x65, 0x61, 0x6d, 0x0d, 0x0a, 0x43, 0x6f, 0x6e,
    0x74, 0x65, 0x6e, 0x74, 0x2d, 0x4c, 0x65, 0x6e,
    0x67, 0x74, 0x68, 0x3a, 0x20, 0x31, 0x31, 0x39,
    0x0d, 0x0a, 0x43, 0x6f, 0x6e, 0x6e, 0x65, 0x63,
    0x74, 0x69, 0x6f, 0x6e, 0x3a, 0x20, 0x6b, 0x65,
    0x65, 0x70, 0x2d, 0x61, 0x6c, 0x69, 0x76, 0x65,
    0x0d, 0x0a, 0x4c, 0x61, 0x73, 0x74, 0x2d, 0x4d,
    0x6f, 0x64, 0x69, 0x66, 0x69, 0x65, 0x64, 0x3a,
    0x20, 0x54, 0x75, 0x65, 0x2c, 0x20, 0x31, 0x30,
    0x20, 0x44, 0x65, 0x63, 0x20, 0x32, 0x30, 0x31,
    0x39, 0x20, 0x31, 0x37, 0x3a, 0x31, 0x34, 0x3a,
    0x30, 0x30, 0x20, 0x47, 0x4d, 0x54, 0x0d, 0x0a,
    0x45, 0x54, 0x61, 0x67, 0x3a, 0x20, 0x22, 0x35,
    0x64, 0x65, 0x66, 0x64, 0x32, 0x35, 0x38, 0x2d,
    0x37, 0x37, 0x22, 0x0d, 0x0a, 0x43, 0x6f, 0x6e,
    0x74, 0x65, 0x6e, 0x74, 0x2d, 0x45, 0x6e, 0x63,
    0x6f, 0x64, 0x69, 0x6e, 0x67, 0x3a, 0x20, 0x62,
    0x72, 0x0d, 0x0a, 0x41, 0x63, 0x63, 0x65, 0x73,
    0x73, 0x2d, 0x43, 0x6f, 0x6e, 0x74, 0x72, 0x6f,
    0x6c, 0x2d, 0x41, 0x6c, 0x6c, 0x6f, 0x77, 0x2d,
    0x43, 0x72, 0x65, 0x64, 0x65, 0x6e, 0x74, 0x69,
    0x61, 0x6c, 0x73, 0x3a, 0x20, 0x74, 0x72, 0x75,
    0x65, 0x0d, 0x0a, 0x41, 0x63, 0x63, 0x65, 0x73,
    0x73, 0x2d, 0x43, 0x6f, 0x6e, 0x74, 0x72, 0x6f,
    0x6c, 0x2d, 0x41, 0x6c, 0x6c, 0x6f, 0x77, 0x2d,
    0x48, 0x65, 0x61, 0x64, 0x65, 0x72, 0x73, 0x3a,
    0x20, 0x41, 0x63, 0x63, 0x65, 0x70, 0x74, 0x2c,
    0x20, 0x58, 0x2d, 0x41, 0x63, 0x63, 0x65, 0x73,
    0x73, 0x2d, 0x54, 0x6f, 0x6b, 0x65, 0x6e, 0x2c,
    0x20, 0x58, 0x2d, 0x41, 0x70, 0x70, 0x6c, 0x69,
    0x63, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x2d, 0x4e,
    0x61, 0x6d, 0x65, 0x2c, 0x20, 0x58, 0x2d, 0x52,
    0x65, 0x71, 0x75, 0x65, 0x73, 0x74, 0x2d, 0x53,
    0x65, 0x6e, 0x74, 0x2d, 0x54, 0x69, 0x6d, 0x65,
    0x0d, 0x0a, 0x41, 0x63, 0x63, 0x65, 0x73, 0x73,
    0x2d, 0x43, 0x6f, 0x6e, 0x74, 0x72, 0x6f, 0x6c,
    0x2d, 0x41, 0x6c, 0x6c, 0x6f, 0x77, 0x2d, 0x4d,
    0x65, 0x74, 0x68, 0x6f, 0x64, 0x73, 0x3a, 0x20,
    0x47, 0x45, 0x54, 0x2c, 0x20, 0x50, 0x4f, 0x53,
    0x54, 0x2c, 0x20, 0x4f, 0x50, 0x54, 0x49, 0x4f,
    0x4e, 0x53, 0x0d, 0x0a, 0x41, 0x63, 0x63, 0x65,
    0x73, 0x73, 0x2d, 0x43, 0x6f, 0x6e, 0x74, 0x72,
    0x6f, 0x6c, 0x2d, 0x41, 0x6c, 0x6c, 0x6f, 0x77,
    0x2d, 0x4f, 0x72, 0x69, 0x67, 0x69, 0x6e, 0x3a,
    0x20, 0x2a, 0x0d, 0x0a, 0x41, 0x63, 0x63, 0x65,
    0x70, 0x74, 0x2d, 0x52, 0x61, 0x6e, 0x67, 0x65,
    0x73, 0x3a, 0x20, 0x62, 0x79, 0x74, 0x65, 0x73,
    0x0d, 0x0a, 0x0d, 0x0a, 0xa1, 0x10, 0x08, 0x00,
    0xe4, 0x2c, 0x70, 0xf7, 0x6e, 0x30, 0x7c, 0xb6,
    0xb0, 0x00, 0x2d, 0x42, 0xab, 0x6e, 0xbc, 0x06,
    0x51, 0x78, 0xe9, 0xab, 0x27, 0x4b, 0xd5, 0x9e,
    0x9c, 0xa6, 0x99, 0x29, 0x51, 0x56, 0xb2, 0xc9,
    0x92, 0x34, 0xb7, 0x72, 0xa1, 0xb3, 0xd9, 0x81,
    0x41, 0x64, 0xb5, 0xae, 0x2d, 0x28, 0xa1, 0xb4,
    0x79, 0x16, 0xd8, 0xcf, 0xdf, 0xe8, 0xdd, 0xdf,
    0x4e, 0x46, 0x45, 0x97, 0xdf, 0x99, 0xa3, 0x09,
    0x98, 0xb0, 0xe7, 0xde, 0xfb, 0xe0, 0x38, 0x0e,
    0xce, 0x2c, 0x85, 0xd7, 0x41, 0x1f, 0xd4, 0x6e,
    0x69, 0x24, 0xaa, 0xc0, 0x34, 0x5c, 0x49, 0x03,
    0x36, 0xe8, 0x3f, 0xb0, 0x82, 0x17, 0x6c, 0x16,
    0xbe, 0xa9, 0x9d, 0x20, 0x92, 0x74, 0x70, 0x09,
    0x16, 0x42, 0x17, 0x23, 0xdf, 0x41, 0x26, 0x92,
    0x03, 0xb4, 0x27 };

    string raw(reinterpret_cast<char*>(data), sizeof (data));
    ResponseParser p;
    auto req = Request::Builder()
        .method(Method::Get)
        .allow_compression(Compression::BROTLI)
        .uri("/")
        .build();

    p.set_context_request(req);
    auto result = p.parse(raw);
    auto res = result.response;
    CHECK(result.state == State::done);
    CHECK(res->compression.type == Compression::BROTLI);
    CHECK_THAT(res->body.to_string(), StartsWith("function UnityProgress"));
}

TEST("chunked") {
    const char * body_raw[] = {
"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse vel eros sit amet ex gravida tempor sit amet sit amet nisi. Sed ultrices, enim mattis sagittis tincidunt, tortor quam fermentum lectus, vitae mattis felis diam quis lorem. Suspendisse facilisis lorem dui, porta consectetur velit consectetur ac. Maecenas libero justo, porta in finibus vitae, blandit sed felis. Donec aliquam, leo eget ultrices tincidunt, purus ante ornare ipsum, sit amet auctor nunc ligula id nisi. Praesent sit amet sapien eget orci porta accumsan. Ut sed tortor ligula. Aliquam odio dolor, volutpat vitae elit eget, aliquet accumsan nisl. In ac placerat ligula.",
"In eu ultrices turpis, in porta risus. Sed erat dui, euismod in pellentesque in, auctor sit amet erat. Fusce consectetur fermentum neque, vel viverra mauris finibus efficitur. Donec blandit accumsan lacus sit amet viverra. In leo erat, mollis et laoreet eu, vulputate id odio. Suspendisse elementum blandit malesuada. Mauris in tellus lobortis, ullamcorper nulla at, elementum ligula. Vestibulum congue consequat tellus vel gravida. Nam in pharetra tortor, vel tempor tellus. Sed ac pulvinar odio, ac convallis augue. Pellentesque tortor dui, eleifend id ante eget, consequat faucibus felis. Nam vitae lacinia tortor. Praesent lacinia quam ac augue pretium, in auctor nunc consectetur. Cras est sapien, commodo quis tincidunt vitae, faucibus eget quam. Praesent placerat enim lectus, vitae cursus erat semper sed.",
"Fusce quis nulla lacus. Nulla non vulputate diam, eget pulvinar sapien. Vivamus congue tortor ut nulla ultrices, sit amet elementum dolor dignissim. Cras gravida, nisl vel venenatis lacinia, urna magna accumsan turpis, eu porta urna ex vel nulla. Integer ut malesuada ante, quis pulvinar risus. Aenean suscipit gravida ante quis vestibulum. Cras id enim a arcu tristique pretium. Ut euismod ante accumsan tempor sollicitudin. Nunc sed risus bibendum, congue ipsum a, ornare est. Pellentesque vitae est auctor, consectetur nunc at, viverra lectus. Sed nunc leo, ullamcorper eu tortor a, lacinia dapibus est. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Cras dictum vel odio at tempus. Mauris quam ligula, viverra eget semper et, ultricies vitae lectus. Maecenas quis libero nibh.",
"Duis congue lacus sit amet rutrum mollis. Donec facilisis mollis arcu vitae lobortis. Donec efficitur mi et diam fringilla finibus. Aenean rhoncus volutpat eleifend. Fusce dictum mauris nunc, at rutrum tortor convallis sed. Phasellus id consequat felis. Maecenas tincidunt nibh nisi, sed blandit velit egestas nec. Integer dapibus dolor felis, ac mollis massa mattis non. Curabitur nisi diam, viverra vel magna et, tempor feugiat tortor. Etiam eu nulla id orci posuere egestas nec non tortor.",
"Nullam quis tempus lectus. Quisque purus est, venenatis at auctor a, laoreet in purus. Ut convallis, odio eget ullamcorper sollicitudin, nunc felis consectetur erat, ac varius neque diam in magna. Aenean quis orci eu urna blandit laoreet. Pellentesque ultricies metus dui, a luctus justo dignissim a. Suspendisse interdum hendrerit facilisis. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aenean facilisis viverra tortor, et malesuada nisl hendrerit vitae. Duis magna ipsum, mattis in feugiat vitae, tristique eget elit. Vivamus quis arcu felis. Praesent et nunc quis dui dictum laoreet. Praesent auctor urna sit amet quam pulvinar fringilla. Integer in elit maximus, mollis neque a, tempor metus. Donec sodales sapien ut lorem tristique, tristique ultricies arcu porta. Morbi mi nisl, efficitur et fermentum vel, aliquam ac erat.",
};
    Body body;
    string body_concat;
    for(auto& it : body_raw) { body.parts.push_back(string(it)); body_concat += string(it); }
    auto req = Request::Builder().method(Method::Post).body(std::move(body)).chunked().compress(Compression::BROTLI).build();
    auto data = req->to_string();
    REQUIRE_THAT(data, StartsWith(
        "POST / HTTP/1.1\r\n"
        "Content-Encoding: br\r\n"
        "Transfer-Encoding: chunked\r\n"
        "\r\n"
    ));
    RequestParser p;
    auto result = p.parse(data);
    CHECK(result.state == State::done);
    CHECK(result.error.value() == 0);
    CHECK(req->compression.type == Compression::BROTLI);
    REQUIRE(req->body.to_string() == body_concat);
}

TEST("corrupted compression") {
    RequestParser p;
    string raw =
        "POST / HTTP/1.1\r\n"
        "Content-Length: 5\r\n"
        "Content-Encoding: br\r\n"
        "\r\n"
        "12345\r\n"
        ;

    auto result = p.parse(raw);
    auto req = result.request;
    CHECK(result.state == State::error);
    CHECK(req->compression.type == Compression::BROTLI);
    CHECK(result.error == errc::uncompression_failure);
}

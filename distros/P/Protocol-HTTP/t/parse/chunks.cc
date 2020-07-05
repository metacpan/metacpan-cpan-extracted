#include "../lib/test.h"

#define TEST(name) TEST_CASE("parse-chunks: " name, "[parse-chunks]")

TEST("trivial chunks") {
    RequestParser p;
    string raw =
        "POST /upload HTTP/1.1\r\n"
        "Transfer-Encoding: chunked\r\n"
        "\r\n"
        "4\r\n"
        "Wiki\r\n"
        "5\r\n"
        "pedia\r\n"
        "E\r\n"
        " in\r\n"
        "\r\n"
        "chunks.\r\n"
        "0\r\n"
        "\r\n"
        ;

    auto result = p.parse(raw);
    auto req = result.request;
    CHECK(result.state == State::done);
    CHECK(req->chunked);
    CHECK(req->headers.fields.size() == 1);
    CHECK(req->headers.get("Transfer-Encoding") == "chunked");
    CHECK(req->body.parts.size() == 3);
    CHECK(req->body.to_string() == "Wikipedia in\r\n\r\nchunks.");
}

TEST("chunks with extension") {
    RequestParser p;
    string raw =
        "POST /upload HTTP/1.1\r\n"
        "Transfer-Encoding: chunked\r\n"
        "\r\n"
        "4;chunkextension=somevalue\r\n"
        "Wiki\r\n"
        "5\r\n"
        "pedia\r\n"
        "E\r\n"
        " in\r\n"
        "\r\n"
        "chunks.\r\n"
        "0\r\n"
        "\r\n"
        ;

    auto result = p.parse(raw);
    auto req = result.request;
    CHECK(result.state == State::done);
    CHECK(req->headers.fields.size() == 1);
    CHECK(req->headers.get("Transfer-Encoding") == "chunked");
    CHECK(req->body.parts.size() == 3);
    CHECK(req->body.to_string() == "Wikipedia in\r\n\r\nchunks.");
}

TEST("chunks with trailer header") {
    RequestParser p;
    string raw =
        "POST /upload HTTP/1.1\r\n"
        "Transfer-Encoding: chunked\r\n"
        "Trailer: Expires\r\n"
        "\r\n"
        "4;chunkextension=somevalue\r\n"
        "Wiki\r\n"
        "5\r\n"
        "pedia\r\n"
        "E\r\n"
        " in\r\n"
        "\r\n"
        "chunks.\r\n"
        "0\r\n"
        "Expires: Wed, 21 Oct 2015 07:28:00 GMT\r\n"
        "\r\n"
        ;

    auto result = p.parse(raw);
    auto req = result.request;
    CHECK(result.state == State::done);
    CHECK(req->headers.fields.size() == 2);
    CHECK(req->headers.get("Transfer-Encoding") == "chunked");
    CHECK(req->body.parts.size() == 3);
    CHECK(req->body.to_string() == "Wikipedia in\r\n\r\nchunks.");
}

TEST("fragmented chunks") {
    RequestParser p;

    std::vector<string> v = {
        "POST /upload HTTP/1.1\r\n"
        "Transfer-Enco", "ding", ": chu", "nked\r\n"
        "Trailer: Expires\r\n"
        "\r\n"
        "4;chunkex", "tension=somevalue\r\n"
        "Wiki\r\n"
        "5\r\n"
        "pedia\r\n"
        "E\r\n"
        " i", "n\r\n"
        "\r\n"
        "chunks.\r\n"
        "0\r\n"
        "Expires: Wed, 21 Oct 20", "15 07:28:00 GMT\r\n"
        "\r\n"
    };

    RequestParser::Result result;
    for (auto s : v) {
        if (result.request) CHECK(result.state != State::done);
        result = p.parse(s);
    }

    auto req = result.request;
    CHECK(result.state == State::done);
    CHECK(req->method_raw() == Method::POST);
    CHECK(req->http_version == 11);
    CHECK(req->headers.get("Transfer-Encoding") == "chunked");
    CHECK(req->headers.get("Trailer") == "Expires");
    CHECK(req->body.to_string() == "Wikipedia in\r\n\r\nchunks.");
}

TEST("unsupported TE") {
    RequestParser p;
    string raw =
        "POST /upload HTTP/1.1\r\n"
        "Transfer-Encoding: XXX\r\n"
        ;

    auto result = p.parse(raw);
    auto req = result.request;
    CHECK(result.state == State::error);
    CHECK(result.error == errc::unsupported_transfer_encoding);
}

TEST("unsupported TE (2)") {
    RequestParser p;
    string raw =
        "POST /upload HTTP/1.1\r\n"
        "Transfer-Encoding: chunked, XXX\r\n"
        ;

    auto result = p.parse(raw);
    auto req = result.request;
    CHECK(result.state == State::error);
    CHECK(result.error == errc::unsupported_transfer_encoding);
}

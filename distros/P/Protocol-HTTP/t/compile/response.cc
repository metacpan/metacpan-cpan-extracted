#include "../lib/test.h"

#define TEST(name) TEST_CASE("compile-response: " name, "[compile-response]")

TEST("code with default message for code") {
    auto res = Response::Builder().code(500).build();
    CHECK(res->to_string() ==
        "HTTP/1.1 500 Internal Server Error\r\n"
        "Content-Length: 0\r\n"
        "\r\n"
    );
}

TEST("custom message") {
    auto res = Response::Builder().code(500).message("a-nuka-nah").build();
    CHECK(res->to_string() ==
        "HTTP/1.1 500 a-nuka-nah\r\n"
        "Content-Length: 0\r\n"
        "\r\n"
    );
}

TEST("default code") {
    auto res = Response::Builder().build();
    CHECK(res->to_string() ==
        "HTTP/1.1 200 OK\r\n"
        "Content-Length: 0\r\n"
        "\r\n"
    );
}

TEST("http version") {
    auto res = Response::Builder().code(200).build();
    string chk = "1.1";
    SECTION("default is 1.1") {}
    SECTION("1.1")            { res->http_version = 11; }
    SECTION("1.0")            { res->http_version = 10; chk = "1.0"; }
    CHECK(res->to_string() ==
        string("HTTP/") + chk + " 200 OK\r\n"
        "Content-Length: 0\r\n"
        "\r\n"
    );
}

TEST("request context: follow connection type unless explicitly specified") {
    auto req = Request::Builder().build();
    auto res = Response::Builder().build();

    SECTION("request is c=close") {
        req->headers.connection("close");
        SECTION("keep") {}
        SECTION("change - ignored") { res->headers.connection("keep-alive"); }
        CHECK(res->to_string(req) ==
            "HTTP/1.1 200 OK\r\n"
            "Connection: close\r\n"
            "Content-Length: 0\r\n"
            "\r\n"
        );
    }

    SECTION("request is keep-alive") {
        SECTION("keep") {
            CHECK(res->to_string(req) ==
                "HTTP/1.1 200 OK\r\n"
                "Content-Length: 0\r\n"
                "\r\n"
            );
        }
        SECTION("change") {
            res->headers.connection("close");
            CHECK(res->to_string(req) ==
                "HTTP/1.1 200 OK\r\n"
                "Connection: close\r\n"
                "Content-Length: 0\r\n"
                "\r\n"
            );
        }
        SECTION("ignore keep-alive for http 1.0 req") {
            req->http_version = 10;
            res->headers.connection("keep-alive");
            CHECK(res->to_string(req) ==
                "HTTP/1.0 200 OK\r\n"
                "Content-Length: 0\r\n"
                "\r\n"
            );
        }
    }
}

TEST("request context: follow http_version unless explicitly specified") {
    auto req = Request::Builder().http_version(10).build();
    auto res = Response::Builder().build();

    SECTION("keep") {
        CHECK(res->to_string(req) ==
            "HTTP/1.0 200 OK\r\n"
            "Content-Length: 0\r\n"
            "\r\n"
        );
    }
    SECTION("change") {
        res->http_version = 11;
        CHECK(res->to_string(req) ==
            "HTTP/1.1 200 OK\r\n"
            "Connection: close\r\n"
            "Content-Length: 0\r\n"
            "\r\n"
        );
    }
}

TEST("response for HEAD request with content-length") {
    auto res = Response::Builder().header("Content-Length", "100500").build();
    CHECK(res->to_string() ==
        "HTTP/1.1 200 OK\r\n"
        "Content-Length: 100500\r\n"
        "\r\n"
    );
}

TEST("example") {
    auto res = Response::Builder()
        .code(500)
        .message("epta")
        .headers(Headers().add("a", "1").add("b", "2"))
        .body("hello")
        .build();

    CHECK(res->to_string() ==
        "HTTP/1.1 500 epta\r\n"
        "Content-Length: 5\r\n"
        "a: 1\r\n"
        "b: 2\r\n"
        "\r\n"
        "hello"
    );
}

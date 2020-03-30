build: mojo.zip
mojo.zip: handler.pl cpanfile app.pl lib
	docker run --rm -v $(PWD):/var/task shogo82148/p5-aws-lambda:build-5.28 \
		cpanm --notest -L extlocal --installdeps .
	zip -r mojo.zip . -x '*.zip'

test:
	docker run --rm -v $(PWD):/var/task shogo82148/p5-aws-lambda:5.28 \
		handler.handle '{"httpMethod": "GET", "path":"/"}'
	docker run --rm -v $(PWD):/var/task shogo82148/p5-aws-lambda:5.28 \
		handler.handle '{"httpMethod": "POST", "path":"/foo", "headers": {"Content-Type": "application/json"}, "body":"{\"hello\":\"lambda\"}"}'

clean:
	rm -f mojo.zip
	rm -rf local
	rm -rf extlocal

.PHONY: build test clean


FROM perl:5.36

RUN cpan -i App::cpanminus
RUN cpanm --cpanfile cpanfile --installdeps .

WORKDIR /app
COPY . .
EXPOSE 8000
CMD ["perl", "app.pl"]
